namespace Neelo.RecurringInvoicing;

using BeDynamic.PropertyManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;

/// <summary>
/// Generates and (optionally) posts invoices from the validated lines, grouping by
/// customer and billing code according to each billing configuration's grouping mode.
/// In grouped mode one invoice is generated per posting date: all the lines of the
/// customer/billing code that share the same posting date go into the same invoice.
/// </summary>
codeunit 81011 "BeDyn Posting Mgt."
{
    var
        Setup: Record "BeDyn Recurring Inv. Setup";
        NoLinesErr: Label 'There are no validated lines in batch %1.', Comment = '%1 = batch';
        NoSelectionErr: Label 'There are no validated lines in the selection.';
        DoneMsg: Label '%1 invoices generated from batch %2.', Comment = '%1 = invoice count, %2 = batch';
        DoneSelectionMsg: Label '%1 invoices generated from the selected lines.', Comment = '%1 = invoice count';

    /// <summary>Processes all the validated lines of the batch, grouping by customer/billing code.</summary>
    procedure PostBatch(BatchCode: Code[20])
    var
        EntryNos: List of [Integer];
    begin
        Setup.GetSetup();
        Setup.TestField(Active);

        EntryNos := GetValidatedEntriesOfBatch(BatchCode);
        if EntryNos.Count() = 0 then
            Error(NoLinesErr, BatchCode);

        Message(DoneMsg, PostEntries(EntryNos), BatchCode);
    end;

    /// <summary>Processes only the validated lines in the given selection.</summary>
    procedure PostSelection(var BufferSelection: Record "BeDyn Invoice Import Buffer")
    var
        EntryNos: List of [Integer];
    begin
        Setup.GetSetup();
        Setup.TestField(Active);

        EntryNos := CollectValidated(BufferSelection);
        if EntryNos.Count() = 0 then
            Error(NoSelectionErr);

        Message(DoneSelectionMsg, PostEntries(EntryNos));
    end;

    /// <summary>Core: groups the given buffer entries by customer/billing code and generates invoices.</summary>
    local procedure PostEntries(EntryNos: List of [Integer]) InvoiceCount: Integer
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        TempKey: Record "BeDyn Customer Billing" temporary;
        Customer: Record Customer;
        CustomerBilling: Record "BeDyn Customer Billing";
        KeyEntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        // Build the distinct list of (customer, billing code) keys present in the entries.
        foreach EntryNo in EntryNos do begin
            Buffer.Get(EntryNo);
            if not TempKey.Get(Buffer."Customer No.", Buffer."Billing Code") then begin
                TempKey.Init();
                TempKey."Customer No." := Buffer."Customer No.";
                TempKey."Billing Code" := Buffer."Billing Code";
                TempKey.Insert();
            end;
        end;

        // Process each (customer, billing code) group according to its grouping mode.
        // The billing key also includes the account, so the same billing code may have
        // several rows; the first one (by account no.) drives the invoice.
        if TempKey.FindSet() then
            repeat
                Customer.Get(TempKey."Customer No.");
                CustomerBilling.Reset();
                CustomerBilling.SetRange("Customer No.", TempKey."Customer No.");
                CustomerBilling.SetRange("Billing Code", TempKey."Billing Code");
                CustomerBilling.FindFirst();
                KeyEntryNos := EntriesForKey(EntryNos, TempKey."Customer No.", TempKey."Billing Code");
                if CustomerBilling.Deposit then
                    InvoiceCount += ProcessDeposits(CustomerBilling, KeyEntryNos)
                else
                    if CustomerBilling."Invoice Grouping" = CustomerBilling."Invoice Grouping"::Grouped then
                        InvoiceCount += ProcessGrouped(Customer, CustomerBilling, KeyEntryNos)
                    else
                        InvoiceCount += ProcessIndividual(Customer, CustomerBilling, KeyEntryNos);
            until TempKey.Next() = 0;
    end;

    local procedure ProcessGrouped(var Customer: Record Customer; var CustomerBilling: Record "BeDyn Customer Billing"; EntryNos: List of [Integer]) Count: Integer
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        PostingDates: List of [Date];
        PostingDate: Date;
        EntryNo: Integer;
    begin
        if EntryNos.Count() = 0 then
            exit(0);

        // One invoice per posting date: all the lines of the group that share the
        // same posting date are invoiced together, in the order they were imported.
        foreach EntryNo in EntryNos do begin
            Buffer.Get(EntryNo);
            if not PostingDates.Contains(Buffer."Posting Date") then
                PostingDates.Add(Buffer."Posting Date");
        end;

        foreach PostingDate in PostingDates do
            Count += CreateGroupedInvoice(Customer, CustomerBilling, EntriesForDate(EntryNos, PostingDate));
    end;

    /// <summary>Creates one invoice with all the given entries (same customer, billing code and posting date).</summary>
    local procedure CreateGroupedInvoice(var Customer: Record Customer; var CustomerBilling: Record "BeDyn Customer Billing"; EntryNos: List of [Integer]): Integer
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        SalesHeader: Record "Sales Header";
        EntryNo: Integer;
    begin
        if EntryNos.Count() = 0 then
            exit(0);

        // The header external doc. no. is taken from the first line of the group.
        Buffer.Get(EntryNos.Get(1));
        CreateHeader(SalesHeader, Customer, CustomerBilling, Buffer);
        foreach EntryNo in EntryNos do begin
            Buffer.Get(EntryNo);
            AddLine(SalesHeader, CustomerBilling, Buffer);
        end;

        FinishInvoice(SalesHeader, EntryNos);
        exit(1);
    end;

    local procedure EntriesForDate(EntryNos: List of [Integer]; PostingDate: Date) Result: List of [Integer]
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        EntryNo: Integer;
    begin
        foreach EntryNo in EntryNos do begin
            Buffer.Get(EntryNo);
            if Buffer."Posting Date" = PostingDate then
                Result.Add(EntryNo);
        end;
    end;

    // ============================ FIANZAS ============================

    /// <summary>
    /// Deposit billing code: instead of generating invoices, each row posts the
    /// collection (bank against the deposit G/L account of the billing row) and creates
    /// a deposit linked to the active reservation of the property/room — created if
    /// there is none. The posting document no. is the deposit no., which identifies the
    /// posted G/L entries from the deposit.
    /// </summary>
    local procedure ProcessDeposits(var CustomerBilling: Record "BeDyn Customer Billing"; EntryNos: List of [Integer]) Count: Integer
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        Deposit: Record "BeDyn Deposit";
        EntryNo: Integer;
    begin
        foreach EntryNo in EntryNos do begin
            Buffer.Get(EntryNo);
            CreateDeposit(Deposit, Buffer);
            PostDepositJournal(Buffer, CustomerBilling, Deposit."No.");

            Deposit.Status := Deposit.Status::Collected;
            Deposit."Collection Date" := Buffer."Posting Date";
            Deposit."Document No." := Deposit."No.";
            // The collection entry is the deposit's accounting entry: with the posting
            // document no. and date stamped, the deposit card blocks a second posting
            // (bridge account against the deposit account) and navigates to the G/L entries.
            Deposit."Posting Document No." := Deposit."No.";
            Deposit."Posting Date" := Buffer."Posting Date";
            Deposit.Modify(true);

            Buffer.Status := Buffer.Status::Posted;
            Buffer."Posted Document No." := Deposit."No.";
            Buffer."Deposit No." := Deposit."No.";
            Buffer.Modify(true);
            Count += 1;
            // Each deposit is complete at this point; committing keeps what is done if a
            // later row fails.
            Commit();
        end;
    end;

    local procedure GetLineReservationRoom(var Buffer: Record "BeDyn Invoice Import Buffer"): Code[20]
    var
        ValidationMgt: Codeunit "BeDyn Validation Mgt.";
    begin
        exit(ValidationMgt.GetReservationRoom(Buffer."Variant Code"));
    end;

    local procedure CreateDeposit(var Deposit: Record "BeDyn Deposit"; var Buffer: Record "BeDyn Invoice Import Buffer")
    var
        ReservationNo: Code[20];
    begin
        ReservationNo := FindOrCreateReservation(Buffer, GetLineReservationRoom(Buffer));
        Clear(Deposit);
        Deposit.Init();
        Deposit."No." := '';
        Deposit.Insert(true);
        Deposit.Validate("Reservation No.", ReservationNo);
        Deposit.Validate(Amount, Buffer.Amount);
        Deposit.Modify(true);
    end;

    /// <summary>
    /// Reservation of the property/room for a CSV row. Among the active reservations
    /// (pending, confirmed or checked-in), when the customer has tenants linked to it,
    /// only its own are reused — the one covering the posting date first, then the most
    /// recent — plus placeholders without tenant; reservations of other tenants are never
    /// reused. Without that link the most recent active reservation is taken, as before.
    /// When none qualifies, a pending reservation is created with the posting date as
    /// start date and the customer's tenant (when it has exactly one), for the user to
    /// complete.
    /// </summary>
    local procedure FindOrCreateReservation(var Buffer: Record "BeDyn Invoice Import Buffer"; RoomNo: Code[20]): Code[20]
    var
        Reservation: Record "BeDyn Reservation";
        CustomerTenant: Record "BeDyn Tenant";
        ReservationNo: Code[20];
    begin
        CustomerTenant.SetRange("Customer No.", Buffer."Customer No.");
        ReservationNo := FindActiveReservation(Buffer, RoomNo, CustomerTenant);
        if ReservationNo <> '' then
            exit(ReservationNo);

        Reservation.Init();
        Reservation."No." := '';
        Reservation.Validate("Property No.", Buffer."Property Code");
        // Direct assign: the room was checked against the rental type at validation, and
        // Validate would reject rooms on full-property rentals.
        Reservation."Room No." := RoomNo;
        Reservation."Start Date" := Buffer."Posting Date";
        if CustomerTenant.Count() = 1 then begin
            CustomerTenant.FindFirst();
            Reservation.Validate("Tenant No.", CustomerTenant."No.");
        end;
        Reservation.Insert(true);
        exit(Reservation."No.");
    end;

    local procedure FindActiveReservation(var Buffer: Record "BeDyn Invoice Import Buffer"; RoomNo: Code[20]; var CustomerTenant: Record "BeDyn Tenant"): Code[20]
    var
        Reservation: Record "BeDyn Reservation";
        CustomerHasTenants: Boolean;
        CoveringNo: Code[20];
        OwnNo: Code[20];
        PlaceholderNo: Code[20];
        AnyNo: Code[20];
    begin
        CustomerHasTenants := not CustomerTenant.IsEmpty();
        Reservation.SetCurrentKey("Property No.", "Room No.", "Start Date");
        Reservation.SetRange("Property No.", Buffer."Property Code");
        Reservation.SetRange("Room No.", RoomNo);
        Reservation.SetFilter(Status, '%1|%2|%3', Reservation.Status::Pending, Reservation.Status::Confirmed, Reservation.Status::CheckedIn);
        if Reservation.FindSet() then
            repeat
                // Ascending by start date: each candidate overwrites the previous one of
                // its kind, so the most recent one wins.
                if not CustomerHasTenants then begin
                    AnyNo := Reservation."No.";
                    if CoversDate(Reservation, Buffer."Posting Date") then
                        CoveringNo := Reservation."No.";
                end else
                    if Reservation."Tenant No." = '' then
                        PlaceholderNo := Reservation."No."
                    else
                        if IsCustomerTenant(CustomerTenant, Reservation."Tenant No.") then begin
                            OwnNo := Reservation."No.";
                            if CoversDate(Reservation, Buffer."Posting Date") then
                                CoveringNo := Reservation."No.";
                        end;
            until Reservation.Next() = 0;
        if CoveringNo <> '' then
            exit(CoveringNo);
        if OwnNo <> '' then
            exit(OwnNo);
        if PlaceholderNo <> '' then
            exit(PlaceholderNo);
        exit(AnyNo);
    end;

    /// <summary>True when the reservation dates include the given date (an open end date counts as ongoing).</summary>
    local procedure CoversDate(var Reservation: Record "BeDyn Reservation"; TheDate: Date): Boolean
    begin
        if (TheDate = 0D) or (Reservation."Start Date" = 0D) then
            exit(false);
        exit((Reservation."Start Date" <= TheDate) and ((Reservation."End Date" = 0D) or (Reservation."End Date" >= TheDate)));
    end;

    local procedure IsCustomerTenant(var CustomerTenant: Record "BeDyn Tenant"; TenantNo: Code[20]): Boolean
    var
        Tenant: Record "BeDyn Tenant";
    begin
        Tenant.CopyFilters(CustomerTenant);
        Tenant.SetRange("No.", TenantNo);
        exit(not Tenant.IsEmpty());
    end;

    /// <summary>
    /// Posts the deposit collection directly (no journal batch): the bank of the billing
    /// row against its deposit G/L account, without VAT, carrying the CSV dimensions.
    /// </summary>
    local procedure PostDepositJournal(var Buffer: Record "BeDyn Invoice Import Buffer"; var CustomerBilling: Record "BeDyn Customer Billing"; DocumentNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := Buffer."Posting Date";
        GenJnlLine."Document Date" := Buffer."Posting Date";
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine."External Document No." := Buffer."External Document No.";
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
        GenJnlLine.Validate("Account No.", CustomerBilling."Management Bank");
        GenJnlLine.Validate(Amount, Buffer.Amount);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", CustomerBilling."Account No.");
        // A deposit carries no VAT: the posting setup inherited from the account is cleared.
        GenJnlLine."Bal. Gen. Posting Type" := GenJnlLine."Bal. Gen. Posting Type"::" ";
        GenJnlLine."Bal. Gen. Bus. Posting Group" := '';
        GenJnlLine."Bal. Gen. Prod. Posting Group" := '';
        GenJnlLine."Bal. VAT Bus. Posting Group" := '';
        GenJnlLine."Bal. VAT Prod. Posting Group" := '';
        if Buffer.Description <> '' then
            GenJnlLine.Description := CopyStr(Buffer.Description, 1, MaxStrLen(GenJnlLine.Description));
        if (Buffer."Business Line Code" <> '') and (Setup."Business Line Dim. Code" <> '') then
            GenJnlLine."Dimension Set ID" := AddDimValue(GenJnlLine."Dimension Set ID", Setup."Business Line Dim. Code", Buffer."Business Line Code");
        if (Buffer."Channel Code" <> '') and (Setup."Channel Dim. Code" <> '') then
            GenJnlLine."Dimension Set ID" := AddDimValue(GenJnlLine."Dimension Set ID", Setup."Channel Dim. Code", Buffer."Channel Code");
        if (Buffer."Unit Code" <> '') and (Setup."Unit Dim. Code" <> '') then
            GenJnlLine."Dimension Set ID" := AddDimValue(GenJnlLine."Dimension Set ID", Setup."Unit Dim. Code", Buffer."Unit Code");
        UpdateShortcutDims(GenJnlLine."Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code");
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure ProcessIndividual(var Customer: Record Customer; var CustomerBilling: Record "BeDyn Customer Billing"; EntryNos: List of [Integer]) Count: Integer
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        SalesHeader: Record "Sales Header";
        AmountEntries: List of [Integer];
        CommentEntries: List of [Integer];
        InvoiceEntries: List of [Integer];
        EntryNo: Integer;
    begin
        SplitComments(EntryNos, AmountEntries, CommentEntries);

        // Special case: exactly one comment + one billable line -> one combined invoice
        // (the comment can only belong to that single line).
        if (CommentEntries.Count() = 1) and (AmountEntries.Count() = 1) then begin
            Buffer.Get(AmountEntries.Get(1));
            CreateHeader(SalesHeader, Customer, CustomerBilling, Buffer);
            AddLine(SalesHeader, CustomerBilling, Buffer);
            Buffer.Get(CommentEntries.Get(1));
            AddLine(SalesHeader, CustomerBilling, Buffer);
            InvoiceEntries.Add(AmountEntries.Get(1));
            InvoiceEntries.Add(CommentEntries.Get(1));
            FinishInvoice(SalesHeader, InvoiceEntries);
            exit(1);
        end;

        // Otherwise: one invoice per billable line; comment lines are ignored because they
        // cannot be linked to a specific invoice.
        foreach EntryNo in AmountEntries do begin
            Buffer.Get(EntryNo);
            CreateHeader(SalesHeader, Customer, CustomerBilling, Buffer);
            AddLine(SalesHeader, CustomerBilling, Buffer);
            Clear(InvoiceEntries);
            InvoiceEntries.Add(EntryNo);
            FinishInvoice(SalesHeader, InvoiceEntries);
            Count += 1;
        end;
        foreach EntryNo in CommentEntries do begin
            Buffer.Get(EntryNo);
            MarkIgnored(Buffer);
        end;
    end;

    /// <summary>Splits entries into billable (amount) lines and comment lines.</summary>
    local procedure SplitComments(EntryNos: List of [Integer]; var AmountEntries: List of [Integer]; var CommentEntries: List of [Integer])
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        EntryNo: Integer;
    begin
        foreach EntryNo in EntryNos do begin
            Buffer.Get(EntryNo);
            if Buffer."Is Comment" then
                CommentEntries.Add(EntryNo)
            else
                AmountEntries.Add(EntryNo);
        end;
    end;

    local procedure GetValidatedEntriesOfBatch(BatchCode: Code[20]) EntryNos: List of [Integer]
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
    begin
        Buffer.SetRange("Import Batch Code", BatchCode);
        Buffer.SetRange(Status, Buffer.Status::Validated);
        if Buffer.FindSet() then
            repeat
                EntryNos.Add(Buffer."Entry No.");
            until Buffer.Next() = 0;
    end;

    local procedure CollectValidated(var BufferSelection: Record "BeDyn Invoice Import Buffer") EntryNos: List of [Integer]
    begin
        if BufferSelection.FindSet() then
            repeat
                if BufferSelection.Status = BufferSelection.Status::Validated then
                    EntryNos.Add(BufferSelection."Entry No.");
            until BufferSelection.Next() = 0;
    end;

    local procedure EntriesForKey(EntryNos: List of [Integer]; CustomerNo: Code[20]; BillingCode: Code[20]) Result: List of [Integer]
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        EntryNo: Integer;
    begin
        foreach EntryNo in EntryNos do begin
            Buffer.Get(EntryNo);
            if (Buffer."Customer No." = CustomerNo) and (Buffer."Billing Code" = BillingCode) then
                Result.Add(EntryNo);
        end;
    end;

    local procedure CreateHeader(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var CustomerBilling: Record "BeDyn Customer Billing"; var Buffer: Record "BeDyn Invoice Import Buffer")
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        // Whether the CSV amounts include VAT comes from the setup and overrides the
        // customer default, so the imported amount is always interpreted like the template.
        SalesHeader.Validate("Prices Including VAT", Setup."Prices Including VAT");
        // The Management Bank comes from the billing configuration (it drives the remittance).
        SalesHeader."Management Bank" := CustomerBilling."Management Bank";

        // Posting/document date and external document no. come from the CSV line.
        if Buffer."Posting Date" <> 0D then begin
            SalesHeader.Validate("Posting Date", Buffer."Posting Date");
            SalesHeader.Validate("Document Date", Buffer."Posting Date");
        end;
        if Buffer."External Document No." <> '' then
            SalesHeader.Validate("External Document No.", Buffer."External Document No.");

        // Rental billing codes: the invoice carries the reservation of the property of
        // its (first) line, found or created on the fly. The field number matches the
        // posted invoice extension, so it is carried over when posting.
        if CustomerBilling.Rental then
            SalesHeader."Reservation No." :=
                FindOrCreateReservation(Buffer, GetLineReservationRoom(Buffer));

        // Individuals template: the business line and channel dimensions (from the first
        // line of the group) are stamped on the header, so the lines inherit them by default.
        if (Buffer."Business Line Code" <> '') and (Setup."Business Line Dim. Code" <> '') then
            SalesHeader."Dimension Set ID" := AddDimValue(SalesHeader."Dimension Set ID", Setup."Business Line Dim. Code", Buffer."Business Line Code");
        if (Buffer."Channel Code" <> '') and (Setup."Channel Dim. Code" <> '') then
            SalesHeader."Dimension Set ID" := AddDimValue(SalesHeader."Dimension Set ID", Setup."Channel Dim. Code", Buffer."Channel Code");
        if (Buffer."Unit Code" <> '') and (Setup."Unit Dim. Code" <> '') then
            SalesHeader."Dimension Set ID" := AddDimValue(SalesHeader."Dimension Set ID", Setup."Unit Dim. Code", Buffer."Unit Code");
        UpdateShortcutDims(SalesHeader."Dimension Set ID", SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code");

        SalesHeader.Modify(true);
    end;

    local procedure AddLine(var SalesHeader: Record "Sales Header"; var CustomerBilling: Record "BeDyn Customer Billing"; var Buffer: Record "BeDyn Invoice Import Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        // Rental billing codes: every billable line must have its reservation (found or
        // created). On grouped invoices only the first one shows on the header, but the
        // reservations of the rest of the lines are ensured here as well.
        if CustomerBilling.Rental and (not Buffer."Is Comment") then
            FindOrCreateReservation(Buffer, GetLineReservationRoom(Buffer));

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := NextLineNo(SalesHeader);
        SalesLine.Insert(true);

        if Buffer."Is Comment" then begin
            // Comment line: blank type, description only (grouped invoices only).
            SalesLine.Validate(Type, SalesLine.Type::" ");
            SalesLine.Validate(Description, Buffer.Description);
        end else begin
            if Buffer."Property Code" <> '' then begin
                // Individuals template: the property from the CSV is the item of the line
                // and the room its variant; the billing configuration account is ignored.
                SalesLine.Validate(Type, SalesLine.Type::Item);
                SalesLine.Validate("No.", Buffer."Property Code");
                if Buffer."Variant Code" <> '' then
                    SalesLine.Validate("Variant Code", Buffer."Variant Code");
            end else begin
                SalesLine.Validate(Type, CustomerBilling.GetSalesLineType());
                SalesLine.Validate("No.", CustomerBilling."Account No.");
                // The variant comes from the billing configuration. It is validated
                // before the price so it does not overwrite the CSV amount.
                if (SalesLine.Type = SalesLine.Type::Item) and (CustomerBilling."Variant Code" <> '') then
                    SalesLine.Validate("Variant Code", CustomerBilling."Variant Code");
            end;
            // The unit of measure of the billing configuration overrides the item default
            // (e.g. the item sells by DAY but this billing code invoices by MONTH). It is
            // validated before the price so it does not overwrite the CSV amount.
            if CustomerBilling."Unit of Measure Code" <> '' then
                SalesLine.Validate("Unit of Measure Code", CustomerBilling."Unit of Measure Code");
            // The CSV VAT product posting group overrides the one inherited from the item/account.
            if Buffer."VAT Prod. Posting Group" <> '' then
                SalesLine.Validate("VAT Prod. Posting Group", Buffer."VAT Prod. Posting Group");
            SalesLine.Validate(Quantity, 1);
            SalesLine.Validate("Unit Price", Buffer.Amount);
            // The CSV concept overrides the item/account description.
            SalesLine.Validate(Description, Buffer.Description);
        end;

        // The business line and channel dimensions are stamped on the line as well: on
        // grouped invoices each line keeps its own value even if it differs from the header's.
        if (Buffer."Business Line Code" <> '') and (Setup."Business Line Dim. Code" <> '') then
            SalesLine."Dimension Set ID" := AddDimValue(SalesLine."Dimension Set ID", Setup."Business Line Dim. Code", Buffer."Business Line Code");
        if (Buffer."Channel Code" <> '') and (Setup."Channel Dim. Code" <> '') then
            SalesLine."Dimension Set ID" := AddDimValue(SalesLine."Dimension Set ID", Setup."Channel Dim. Code", Buffer."Channel Code");
        if (Buffer."Unit Code" <> '') and (Setup."Unit Dim. Code" <> '') then
            SalesLine."Dimension Set ID" := AddDimValue(SalesLine."Dimension Set ID", Setup."Unit Dim. Code", Buffer."Unit Code");
        UpdateShortcutDims(SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
        SalesLine.Modify(true);
    end;

    /// <summary>Merges a dimension value into the given dimension set.</summary>
    local procedure AddDimValue(DimSetID: Integer; DimCode: Code[20]; DimValueCode: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValue: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
    begin
        DimensionValue.Get(DimCode, DimValueCode);
        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        TempDimSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        if TempDimSetEntry.FindFirst() then
            TempDimSetEntry.Delete();
        TempDimSetEntry.Reset();
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimSetEntry.Insert();
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure UpdateShortcutDims(DimSetID: Integer; var ShortcutDim1: Code[20]; var ShortcutDim2: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.UpdateGlobalDimFromDimSetID(DimSetID, ShortcutDim1, ShortcutDim2);
    end;

    local procedure NextLineNo(var SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;

    /// <summary>Posts the invoice if Default Posting; otherwise leaves it as a draft. Returns the document no.</summary>
    local procedure PostOrLeaveDraft(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesPost: Codeunit "Sales-Post";
        PreAssignedNo: Code[20];
    begin
        if not Setup."Default Posting" then
            exit(SalesHeader."No."); // draft

        PreAssignedNo := SalesHeader."No.";
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        Clear(SalesPost);
        SalesPost.Run(SalesHeader);

        SalesInvHeader.SetCurrentKey("Pre-Assigned No.");
        SalesInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        if SalesInvHeader.FindLast() then
            exit(SalesInvHeader."No.");
        exit('');
    end;

    /// <summary>
    /// Closes an invoice built from the given buffer entries. The entries are marked
    /// processed with the draft no. and committed before posting: Sales-Post commits on
    /// its own, so an error while posting could otherwise lose the mark of an invoice
    /// already posted, or leave a draft whose lines would be invoiced again on the next
    /// run. After a successful posting the entries are updated with the posted no.
    /// </summary>
    local procedure FinishInvoice(var SalesHeader: Record "Sales Header"; EntryNos: List of [Integer])
    var
        PostedNo: Code[20];
    begin
        MarkEntriesProcessed(EntryNos, SalesHeader."No.");
        Commit();
        PostedNo := PostOrLeaveDraft(SalesHeader);
        if Setup."Default Posting" and (PostedNo <> '') then begin
            MarkEntriesProcessed(EntryNos, PostedNo);
            Commit();
        end;
    end;

    local procedure MarkEntriesProcessed(EntryNos: List of [Integer]; DocumentNo: Code[20])
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        EntryNo: Integer;
    begin
        foreach EntryNo in EntryNos do begin
            Buffer.Get(EntryNo);
            MarkProcessed(Buffer, DocumentNo);
        end;
    end;

    local procedure MarkProcessed(var Buffer: Record "BeDyn Invoice Import Buffer"; PostedNo: Code[20])
    begin
        Buffer.Status := Buffer.Status::Posted;
        Buffer."Posted Document No." := PostedNo;
        Buffer.Modify(true);
    end;

    local procedure MarkIgnored(var Buffer: Record "BeDyn Invoice Import Buffer")
    begin
        Buffer.Status := Buffer.Status::Ignored;
        Buffer."Posted Document No." := '';
        Buffer.Modify(true);
    end;
}
