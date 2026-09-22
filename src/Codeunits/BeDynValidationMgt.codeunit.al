namespace Neelo.RecurringInvoicing;

using BeDynamic.PropertyManagement;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;

/// <summary>
/// Validates the lines of a buffer batch, flagging each one Validated / Error.
/// Resolves the customer by Tax ID and its billing configuration by billing code.
/// </summary>
codeunit 81010 "BeDyn Validation Mgt."
{
    // La validación crea al vuelo los valores de la dimensión de unidad que faltan;
    // el permiso se eleva a nivel de objeto para no depender del permiso del usuario
    // sobre los valores de dimensión.
    Permissions = tabledata "Dimension Value" = rim;

    var
        Setup: Record "BeDyn Recurring Inv. Setup";
        ValidatedMsg: Label '%1 lines validated, %2 with errors (batch %3).', Comment = '%1 ok, %2 error, %3 batch';
        CustNotFoundErr: Label 'No customer found with Tax ID "%1".', Comment = '%1 = Tax ID';
        CustAmbiguousErr: Label 'Tax ID "%1" matches more than one customer; specify the BC ID to choose one.', Comment = '%1 = Tax ID';
        CustBlockedErr: Label 'Customer %1 is blocked (%2).', Comment = '%1 customer, %2 blocked';
        NoGroupingErr: Label 'Customer %1 has no customer posting group.', Comment = '%1 customer';
        BillingNotFoundErr: Label 'Customer %1 has no billing configuration "%2".', Comment = '%1 customer, %2 billing code';
        BankBlockedErr: Label 'Management Bank %1 does not exist or is blocked.', Comment = '%1 bank';
        AccountErr: Label 'The account %1 (%2) does not exist or is blocked.', Comment = '%1 no., %2 type';
        VariantErr: Label 'The variant %1 of item %2 does not exist or is blocked.', Comment = '%1 variant, %2 item';
        VariantRequiredErr: Label 'Item %1 requires a variant; specify it in the billing configuration "%2".', Comment = '%1 item, %2 billing code';
        UoMErr: Label 'The unit of measure %1 does not exist for %2 %3.', Comment = '%1 unit of measure, %2 account type, %3 account no.';
        ZeroAmountErr: Label 'The amount cannot be zero.';
        CommentIndividualErr: Label 'Lines without an amount can only be imported as comments when the billing code uses grouped invoicing; billing code "%1" of customer %2 uses individual invoicing.', Comment = '%1 billing code, %2 customer';
        CustomNIFNotSupportedErr: Label 'The "Custom Tax ID field" source is not implemented yet.';
        VATProdGroupErr: Label 'VAT product posting group "%1" does not exist.', Comment = '%1 = VAT product posting group';
        PropertyItemErr: Label 'The property %1 does not exist as an item or is blocked.', Comment = '%1 = property / item no.';
        RoomRequiredErr: Label 'Item %1 requires a variant; specify the room in the CSV.', Comment = '%1 = item';
        ItemUoMErr: Label 'The unit of measure %1 of the billing configuration does not exist for item %2. Add it to the item units of measure.', Comment = '%1 = unit of measure, %2 = item';
        NoBusinessLineDimErr: Label 'The CSV brings a business line but the "Business Line Dimension Code" is not set in the Recurring Invoicing Setup.';
        BusinessLineErr: Label 'The business line %1 does not exist as a value of dimension %2 or is blocked.', Comment = '%1 = dimension value, %2 = dimension';
        NoChannelDimErr: Label 'The CSV brings a channel but the "Channel Dimension Code" is not set in the Recurring Invoicing Setup.';
        ChannelErr: Label 'The channel %1 does not exist as a value of dimension %2 or is blocked.', Comment = '%1 = dimension value, %2 = dimension';
        NoUnitDimErr: Label 'The CSV brings a unit but the "Unit Dimension Code" is not set in the Recurring Invoicing Setup.';
        UnitBlockedErr: Label 'The unit %1 of dimension %2 is blocked.', Comment = '%1 = dimension value, %2 = dimension';
        DepositNoPropertyErr: Label 'Deposit lines must bring the property in the property column; import them with the individuals CSV layout.';
        DepositPropertyErr: Label 'The property %1 does not exist.', Comment = '%1 = property';
        DepositRoomErr: Label 'The room %1 does not exist in property %2.', Comment = '%1 = room, %2 = property';
        DepositAccountTypeErr: Label 'Deposit billing code %1: the account type must be G/L Account (the deposit liability account).', Comment = '%1 = billing code';
        DepositBankErr: Label 'Deposit billing code %1: the Management Bank (counterpart of the posting) is required.', Comment = '%1 = billing code';
        RentalNoPropertyErr: Label 'Rental lines must bring the property in the property column; import them with the individuals CSV layout.';
        RoomRequiredByRoomErr: Label 'Property %1 is rented by room; specify the room in the CSV.', Comment = '%1 = property';
        RoomNotAllowedErr: Label 'Property %1 is rented as a whole; leave the room blank or use the master room code instead of %2.', Comment = '%1 = property, %2 = room';

    /// <summary>Validates all pending/error lines in the given batch.</summary>
    procedure ValidateBatch(BatchCode: Code[20])
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        OkCount: Integer;
        ErrCount: Integer;
    begin
        Setup.GetSetup();
        Setup.TestField(Active);

        Buffer.SetRange("Import Batch Code", BatchCode);
        Buffer.SetFilter(Status, '%1|%2|%3', Buffer.Status::Pending, Buffer.Status::Error, Buffer.Status::Validated);
        if Buffer.FindSet(true) then
            repeat
                ValidateLine(Buffer);
                Buffer.Modify(true);
                if Buffer.Status = Buffer.Status::Validated then
                    OkCount += 1
                else
                    ErrCount += 1;
            until Buffer.Next() = 0;

        Message(ValidatedMsg, OkCount, ErrCount, BatchCode);
    end;

    /// <summary>Validates a single line, capturing the first error found.</summary>
    procedure ValidateLine(var Buffer: Record "BeDyn Invoice Import Buffer")
    var
        Customer: Record Customer;
        CustomerBilling: Record "BeDyn Customer Billing";
        ErrorText: Text;
    begin
        if Setup."Primary Key" = '' then
            Setup.GetSetup();

        Buffer."Error Message" := '';
        Buffer."Customer No." := '';
        Buffer."Is Comment" := false;
        Buffer."Management Bank" := '';

        ErrorText := ResolveCustomer(Buffer."VAT Registration No.", Buffer."BC Customer No.", Customer);
        if ErrorText = '' then begin
            Buffer."Customer No." := Customer."No.";
            ErrorText := ValidateCustomer(Customer);
        end;
        if ErrorText = '' then
            ErrorText := ResolveBilling(Customer."No.", Buffer."Billing Code", CustomerBilling);
        // Deposit billing codes post a collection instead of invoicing; individuals
        // template lines (with a property) invoice the item/variant from the CSV, so
        // that pair is validated instead of the billing configuration account.
        if ErrorText = '' then
            if CustomerBilling.Deposit then
                ErrorText := ValidateDeposit(Buffer, CustomerBilling)
            else
                if Buffer.Amount = 0 then
                    ErrorText := EvaluateEmptyAmount(Buffer, CustomerBilling)
                else
                    if Buffer."Property Code" <> '' then
                        ErrorText := ValidateBufferItem(Buffer, CustomerBilling)
                    else
                        ErrorText := ValidateAccount(CustomerBilling);
        if (ErrorText = '') and (not Buffer."Is Comment") and (Buffer."Property Code" = '') and (not CustomerBilling.Deposit) then
            ErrorText := ValidateVariantAndUoM(CustomerBilling);
        // Rental billing codes also link the reservation, so each billable line must
        // bring an existing property (and room).
        if (ErrorText = '') and CustomerBilling.Rental and (not Buffer."Is Comment") then
            ErrorText := ValidateRentalProperty(Buffer);
        if ErrorText = '' then
            ErrorText := ValidateBank(CustomerBilling);
        if (ErrorText = '') and (Buffer."VAT Prod. Posting Group" <> '') then
            ErrorText := ValidateVATProdGroup(Buffer."VAT Prod. Posting Group");
        if (ErrorText = '') and (Buffer."Business Line Code" <> '') then
            ErrorText := ValidateBusinessLine(Buffer."Business Line Code");
        if (ErrorText = '') and (Buffer."Channel Code" <> '') then
            ErrorText := ValidateChannel(Buffer."Channel Code");
        if (ErrorText = '') and (Buffer."Unit Code" <> '') then
            ErrorText := ValidateUnit(Buffer."Unit Code");

        if ErrorText <> '' then begin
            Buffer.Status := Buffer.Status::Error;
            Buffer."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(Buffer."Error Message"));
            exit;
        end;

        // No errors: copy the billing configuration to the line.
        Buffer."Invoice Grouping" := CustomerBilling."Invoice Grouping";
        Buffer."Management Bank" := CustomerBilling."Management Bank";
        Buffer.Status := Buffer.Status::Validated;
    end;

    /// <summary>
    /// Locates the customer billing configuration for the CSV billing code. The key also
    /// includes the account, so the same billing code may have several rows; the first
    /// one (by account no.) is used.
    /// </summary>
    local procedure ResolveBilling(CustomerNo: Code[20]; BillingCode: Code[20]; var CustomerBilling: Record "BeDyn Customer Billing"): Text
    begin
        CustomerBilling.SetRange("Customer No.", CustomerNo);
        CustomerBilling.SetRange("Billing Code", BillingCode);
        if (BillingCode = '') or (not CustomerBilling.FindFirst()) then
            exit(StrSubstNo(BillingNotFoundErr, CustomerNo, BillingCode));
        exit('');
    end;

    /// <summary>
    /// Decides how to handle a line with no amount, per the "Insert Comments" setup:
    /// off -> error; on + grouped billing code -> comment line; on + individual -> error.
    /// </summary>
    local procedure EvaluateEmptyAmount(var Buffer: Record "BeDyn Invoice Import Buffer"; var CustomerBilling: Record "BeDyn Customer Billing"): Text
    begin
        if not Setup."Insert Comments" then
            exit(ZeroAmountErr);

        // Individual billing codes: a comment cannot be linked to a specific invoice. Without
        // "Ignore Comments" this is an error; with it the comment is kept and the posting
        // step decides whether to combine (1 comment + 1 line) or ignore it.
        if CustomerBilling."Invoice Grouping" = CustomerBilling."Invoice Grouping"::Individual then
            if not Setup."Ignore Comments" then
                exit(StrSubstNo(CommentIndividualErr, CustomerBilling."Billing Code", CustomerBilling."Customer No."));

        Buffer."Is Comment" := true;
        exit('');
    end;

    /// <summary>
    /// Locates the customer by Tax ID. Returns '' on success, or the error text.
    /// When the Tax ID matches several customers, the BC ID from the CSV (BCHint) is used to
    /// pick the right one; it must be one of the matching customers.
    /// </summary>
    local procedure ResolveCustomer(NIF: Text[20]; BCHint: Code[20]; var Customer: Record Customer): Text
    var
        NormalizedNIF: Text;
        Matches: List of [Code[20]];
    begin
        if Setup."NIF Source" = Setup."NIF Source"::"Custom NIF" then
            // TODO: confirm the custom customer Tax ID field and resolve it here.
            exit(CustomNIFNotSupportedErr);

        NormalizedNIF := NormalizeNIF(NIF);
        if NormalizedNIF = '' then begin
            // Individuals template: the Tax ID column may come empty and the customer
            // is then identified directly by the BC ID column.
            if (BCHint <> '') and Customer.Get(BCHint) then
                exit('');
            exit(StrSubstNo(CustNotFoundErr, NIF));
        end;

        if Customer.FindSet() then
            repeat
                if NormalizeNIF(Customer."VAT Registration No.") = NormalizedNIF then
                    Matches.Add(Customer."No.");
            until Customer.Next() = 0;

        case Matches.Count() of
            0:
                exit(StrSubstNo(CustNotFoundErr, NIF));
            1:
                begin
                    Customer.Get(Matches.Get(1));
                    exit('');
                end;
            else begin
                // Several customers share the Tax ID: disambiguate with the BC ID column.
                if (BCHint <> '') and Matches.Contains(BCHint) then begin
                    Customer.Get(BCHint);
                    exit('');
                end;
                exit(StrSubstNo(CustAmbiguousErr, NIF));
            end;
        end;
    end;

    local procedure ValidateCustomer(var Customer: Record Customer): Text
    begin
        if Customer.Blocked in [Customer.Blocked::Invoice, Customer.Blocked::All] then
            exit(StrSubstNo(CustBlockedErr, Customer."No.", Format(Customer.Blocked)));

        if Customer."Customer Posting Group" = '' then
            exit(StrSubstNo(NoGroupingErr, Customer."No."));

        exit('');
    end;

    local procedure ValidateBank(var CustomerBilling: Record "BeDyn Customer Billing"): Text
    var
        BankAccount: Record "Bank Account";
    begin
        // The Management Bank is optional; when blank the invoice simply carries no bank.
        if CustomerBilling."Management Bank" = '' then
            exit('');

        if not BankAccount.Get(CustomerBilling."Management Bank") then
            exit(StrSubstNo(BankBlockedErr, CustomerBilling."Management Bank"));
        if BankAccount.Blocked then
            exit(StrSubstNo(BankBlockedErr, CustomerBilling."Management Bank"));

        exit('');
    end;

    local procedure ValidateAccount(var CustomerBilling: Record "BeDyn Customer Billing"): Text
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
    begin
        if CustomerBilling."Account No." = '' then
            exit(StrSubstNo(AccountErr, CustomerBilling."Account No.", Format(CustomerBilling."Account Type")));

        case CustomerBilling."Account Type" of
            CustomerBilling."Account Type"::"G/L Account":
                if (not GLAccount.Get(CustomerBilling."Account No.")) or GLAccount.Blocked or (GLAccount."Account Type" <> GLAccount."Account Type"::Posting) then
                    exit(StrSubstNo(AccountErr, CustomerBilling."Account No.", Format(CustomerBilling."Account Type")));
            CustomerBilling."Account Type"::Item:
                if (not Item.Get(CustomerBilling."Account No.")) or Item.Blocked then
                    exit(StrSubstNo(AccountErr, CustomerBilling."Account No.", Format(CustomerBilling."Account Type")));
            CustomerBilling."Account Type"::Resource:
                if (not Resource.Get(CustomerBilling."Account No.")) or Resource.Blocked then
                    exit(StrSubstNo(AccountErr, CustomerBilling."Account No.", Format(CustomerBilling."Account Type")));
        end;
        exit('');
    end;

    /// <summary>
    /// Checks the variant and unit of measure of the billing configuration: the variant must
    /// exist and not be blocked (and is required when the item demands one), and the unit of
    /// measure must exist for the item/resource.
    /// </summary>
    local procedure ValidateVariantAndUoM(var CustomerBilling: Record "BeDyn Customer Billing"): Text
    var
        ItemVariant: Record "Item Variant";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if CustomerBilling."Account Type" = CustomerBilling."Account Type"::Item then
            if CustomerBilling."Variant Code" <> '' then begin
                if (not ItemVariant.Get(CustomerBilling."Account No.", CustomerBilling."Variant Code")) or ItemVariant.Blocked then
                    exit(StrSubstNo(VariantErr, CustomerBilling."Variant Code", CustomerBilling."Account No."));
            end else
                if VariantMandatory(CustomerBilling."Account No.") then
                    exit(StrSubstNo(VariantRequiredErr, CustomerBilling."Account No.", CustomerBilling."Billing Code"));

        if CustomerBilling."Unit of Measure Code" <> '' then
            case CustomerBilling."Account Type" of
                CustomerBilling."Account Type"::Item:
                    if not ItemUnitOfMeasure.Get(CustomerBilling."Account No.", CustomerBilling."Unit of Measure Code") then
                        exit(StrSubstNo(UoMErr, CustomerBilling."Unit of Measure Code", Format(CustomerBilling."Account Type"), CustomerBilling."Account No."));
                CustomerBilling."Account Type"::Resource:
                    if not ResourceUnitOfMeasure.Get(CustomerBilling."Account No.", CustomerBilling."Unit of Measure Code") then
                        exit(StrSubstNo(UoMErr, CustomerBilling."Unit of Measure Code", Format(CustomerBilling."Account Type"), CustomerBilling."Account No."));
                else
                    if not UnitOfMeasure.Get(CustomerBilling."Unit of Measure Code") then
                        exit(StrSubstNo(UoMErr, CustomerBilling."Unit of Measure Code", Format(CustomerBilling."Account Type"), CustomerBilling."Account No."));
            end;
        exit('');
    end;

    /// <summary>
    /// True when the item has variants and demands one ("Variant Mandatory if Exists" on the
    /// item, or the Inventory Setup default when the item setting is Default).
    /// </summary>
    local procedure VariantMandatory(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        InventorySetup: Record "Inventory Setup";
    begin
        if not Item.Get(ItemNo) then
            exit(false);
        ItemVariant.SetRange("Item No.", ItemNo);
        ItemVariant.SetRange(Blocked, false);
        if ItemVariant.IsEmpty() then
            exit(false);
        case Item."Variant Mandatory if Exists" of
            Item."Variant Mandatory if Exists"::No:
                exit(false);
            Item."Variant Mandatory if Exists"::Yes:
                exit(true);
            else begin
                InventorySetup.Get();
                exit(InventorySetup."Variant Mandatory if Exists");
            end;
        end;
    end;

    /// <summary>
    /// Individuals template: the item is the property from the CSV and the variant is the
    /// room. Both must exist and not be blocked, the room is required when the item
    /// demands a variant, and the unit of measure of the billing configuration (assigned
    /// to the invoice line) must exist for the item.
    /// </summary>
    local procedure ValidateBufferItem(var Buffer: Record "BeDyn Invoice Import Buffer"; var CustomerBilling: Record "BeDyn Customer Billing"): Text
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if (not Item.Get(Buffer."Property Code")) or Item.Blocked then
            exit(StrSubstNo(PropertyItemErr, Buffer."Property Code"));

        if Buffer."Variant Code" <> '' then begin
            if (not ItemVariant.Get(Buffer."Property Code", Buffer."Variant Code")) or ItemVariant.Blocked then
                exit(StrSubstNo(VariantErr, Buffer."Variant Code", Buffer."Property Code"));
        end else
            if VariantMandatory(Buffer."Property Code") then
                exit(StrSubstNo(RoomRequiredErr, Buffer."Property Code"));

        if CustomerBilling."Unit of Measure Code" <> '' then
            if not ItemUnitOfMeasure.Get(Buffer."Property Code", CustomerBilling."Unit of Measure Code") then
                exit(StrSubstNo(ItemUoMErr, CustomerBilling."Unit of Measure Code", Buffer."Property Code"));
        exit('');
    end;

    /// <summary>
    /// The business line of the CSV must be an existing, unblocked value of the dimension
    /// configured in the setup.
    /// </summary>
    local procedure ValidateBusinessLine(BusinessLineCode: Code[20]): Text
    var
        DimensionValue: Record "Dimension Value";
    begin
        if Setup."Business Line Dim. Code" = '' then
            exit(NoBusinessLineDimErr);
        if (not DimensionValue.Get(Setup."Business Line Dim. Code", BusinessLineCode)) or DimensionValue.Blocked then
            exit(StrSubstNo(BusinessLineErr, BusinessLineCode, Setup."Business Line Dim. Code"));
        exit('');
    end;

    /// <summary>
    /// Deposit billing codes: no invoice is generated, so the row must carry everything
    /// needed to post the collection and link the deposit — a non-zero amount, an
    /// existing property with a room consistent with its rental type (see
    /// ValidatePropertyRoom), the deposit G/L account on the billing row and the
    /// counterpart bank.
    /// </summary>
    local procedure ValidateDeposit(var Buffer: Record "BeDyn Invoice Import Buffer"; var CustomerBilling: Record "BeDyn Customer Billing"): Text
    var
        ErrorText: Text;
    begin
        if Buffer.Amount = 0 then
            exit(ZeroAmountErr);
        if Buffer."Property Code" = '' then
            exit(DepositNoPropertyErr);
        ErrorText := ValidatePropertyRoom(Buffer);
        if ErrorText <> '' then
            exit(ErrorText);
        if CustomerBilling."Account Type" <> CustomerBilling."Account Type"::"G/L Account" then
            exit(StrSubstNo(DepositAccountTypeErr, CustomerBilling."Billing Code"));
        if CustomerBilling."Management Bank" = '' then
            exit(StrSubstNo(DepositBankErr, CustomerBilling."Billing Code"));
        exit(ValidateAccount(CustomerBilling));
    end;

    /// <summary>
    /// Rental billing codes: the property of the line must exist, with a room consistent
    /// with its rental type, to find or create its reservation.
    /// </summary>
    local procedure ValidateRentalProperty(var Buffer: Record "BeDyn Invoice Import Buffer"): Text
    begin
        if Buffer."Property Code" = '' then
            exit(RentalNoPropertyErr);
        exit(ValidatePropertyRoom(Buffer));
    end;

    /// <summary>
    /// Property and room of a CSV row for the reservation link. The property must exist
    /// and the room must match its rental type, mirroring what confirming the
    /// reservation will demand: an existing room when the property is rented by room,
    /// and no room (blank or the master room code) when it is rented as a whole.
    /// </summary>
    local procedure ValidatePropertyRoom(var Buffer: Record "BeDyn Invoice Import Buffer"): Text
    var
        Property: Record "BeDyn Property";
        PropertyRoom: Record "BeDyn Property Room";
        RoomNo: Code[20];
    begin
        if not Property.Get(Buffer."Property Code") then
            exit(StrSubstNo(DepositPropertyErr, Buffer."Property Code"));
        RoomNo := GetReservationRoom(Buffer."Variant Code");
        if Property."Rental Type" = Property."Rental Type"::"By Room" then begin
            if RoomNo = '' then
                exit(StrSubstNo(RoomRequiredByRoomErr, Buffer."Property Code"));
            if not PropertyRoom.Get(Buffer."Property Code", RoomNo) then
                exit(StrSubstNo(DepositRoomErr, RoomNo, Buffer."Property Code"));
        end else
            if RoomNo <> '' then
                exit(StrSubstNo(RoomNotAllowedErr, Buffer."Property Code", RoomNo));
        exit('');
    end;

    /// <summary>
    /// Room used for the reservation of a CSV row: the room column, except the master
    /// room code of the property setup, which means the whole property (blank room).
    /// </summary>
    procedure GetReservationRoom(VariantCode: Code[10]): Code[20]
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
    begin
        if VariantCode = '' then
            exit('');
        PropertySetup.GetInstance();
        if VariantCode = PropertySetup."Master Room Code" then
            exit('');
        exit(VariantCode);
    end;

    /// <summary>
    /// The channel of the CSV must be an existing, unblocked value of the dimension
    /// configured in the setup.
    /// </summary>
    local procedure ValidateChannel(ChannelCode: Code[20]): Text
    var
        DimensionValue: Record "Dimension Value";
    begin
        if Setup."Channel Dim. Code" = '' then
            exit(NoChannelDimErr);
        if (not DimensionValue.Get(Setup."Channel Dim. Code", ChannelCode)) or DimensionValue.Blocked then
            exit(StrSubstNo(ChannelErr, ChannelCode, Setup."Channel Dim. Code"));
        exit('');
    end;

    /// <summary>
    /// The unit of the CSV must be a value of the dimension configured in the setup.
    /// A missing value is created automatically (with the code as its name); a blocked
    /// value still fails.
    /// </summary>
    local procedure ValidateUnit(UnitCode: Code[20]): Text
    var
        DimensionValue: Record "Dimension Value";
    begin
        if Setup."Unit Dim. Code" = '' then
            exit(NoUnitDimErr);
        if not DimensionValue.Get(Setup."Unit Dim. Code", UnitCode) then begin
            DimensionValue.Init();
            DimensionValue.Validate("Dimension Code", Setup."Unit Dim. Code");
            DimensionValue.Validate(Code, UnitCode);
            DimensionValue.Validate(Name, UnitCode);
            DimensionValue.Insert(true);
            exit('');
        end;
        if DimensionValue.Blocked then
            exit(StrSubstNo(UnitBlockedErr, UnitCode, Setup."Unit Dim. Code"));
        exit('');
    end;

    local procedure ValidateVATProdGroup(VATProdGroupCode: Code[20]): Text
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if not VATProductPostingGroup.Get(VATProdGroupCode) then
            exit(StrSubstNo(VATProdGroupErr, VATProdGroupCode));
        exit('');
    end;

    /// <summary>Normalizes the Tax ID: uppercase, without spaces, dots or dashes.</summary>
    local procedure NormalizeNIF(NIF: Text): Text
    begin
        exit(UpperCase(DelChr(NIF, '=', ' .-')));
    end;
}
