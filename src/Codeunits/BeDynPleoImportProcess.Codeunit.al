namespace BeDynamic.PleoImport;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;

codeunit 82102 "BeDyn Pleo Import Process"
{
    // Genera los documentos a partir de las líneas validadas del buffer:
    //   · Compra tarjeta con importe negativo  -> Factura de compra (IVA incluido) + pago banco Pleo.
    //   · Compra tarjeta con importe positivo  -> Abono de compra + reembolso banco Pleo.
    //   · Recarga monedero                     -> Diario: banco Pleo contra banco de origen.
    //   · Cashback                             -> Diario: banco Pleo contra cuenta de ingresos.
    // Cada línea del CSV es un documento de una sola línea.

    var
        Setup: Record "BeDyn Pleo Setup";

    procedure ProcessLines(var BufferParam: Record "BeDyn Pleo Import Buffer")
    var
        Buffer: Record "BeDyn Pleo Import Buffer";
        DoneCount: Integer;
        ErrorCount: Integer;
        ArchivedCount: Integer;
        NothingMsg: Label 'No hay líneas validadas pendientes de procesar en el filtro actual.';
        DoneMsg: Label 'Proceso terminado: %1 líneas procesadas correctamente, %2 con error. %3 líneas movidas al archivo.', Comment = '%1, %2, %3 = contadores';
    begin
        Setup.GetSetup();
        if Setup."Post Action" = Setup."Post Action"::"Post & Pay" then
            Setup.TestField("Pleo Bank Account No.");

        Buffer.Copy(BufferParam);
        Buffer.SetRange(Status, Buffer.Status::Validated);
        if not Buffer.FindSet(true) then begin
            Message(NothingMsg);
            exit;
        end;
        repeat
            if ProcessLine(Buffer) then
                DoneCount += 1
            else
                ErrorCount += 1;
        until Buffer.Next() = 0;

        ArchivedCount := ArchiveProcessedLines(BufferParam);
        Message(DoneMsg, DoneCount, ErrorCount, ArchivedCount);
    end;

    // Mueve al archivo las líneas con resultado final (documento creado, registrada
    // o pagada) y las elimina del staging. Devuelve cuántas se han archivado.
    procedure ArchiveProcessedLines(var BufferParam: Record "BeDyn Pleo Import Buffer") ArchivedCount: Integer
    var
        Buffer: Record "BeDyn Pleo Import Buffer";
        Archive: Record "BeDyn Pleo Expense Archive";
    begin
        Buffer.Copy(BufferParam);
        Buffer.SetFilter(Status, '%1|%2|%3', Buffer.Status::Created, Buffer.Status::Posted, Buffer.Status::Paid);
        if not Buffer.FindSet(true) then
            exit(0);
        repeat
            Archive.ArchiveFromBuffer(Buffer);
            ArchivedCount += 1;
        until Buffer.Next() = 0;
        Buffer.DeleteAll();
    end;

    // Mueve al archivo las líneas omitidas de la selección y las elimina del
    // staging. Devuelve cuántas se han archivado.
    procedure ArchiveSkippedLines(var BufferParam: Record "BeDyn Pleo Import Buffer") ArchivedCount: Integer
    var
        Buffer: Record "BeDyn Pleo Import Buffer";
        Archive: Record "BeDyn Pleo Expense Archive";
    begin
        Buffer.Copy(BufferParam);
        Buffer.SetRange(Status, Buffer.Status::Skipped);
        if not Buffer.FindSet(true) then
            exit(0);
        repeat
            Archive.ArchiveFromBuffer(Buffer);
            ArchivedCount += 1;
        until Buffer.Next() = 0;
        Buffer.DeleteAll();
    end;

    // ============================ VISTA PREVIA ============================

    // Construye la vista previa de lo que generará el registro de las líneas
    // validadas de la selección, sin escribir nada en BC. Refleja las mismas
    // decisiones que ProcessLine: tipo de documento por signo, gasto
    // extraordinario, recarga, cashback y acción según la configuración.
    procedure BuildPreview(var BufferParam: Record "BeDyn Pleo Import Buffer"; var TempPreview: Record "BeDyn Pleo Posting Preview" temporary)
    var
        Buffer: Record "BeDyn Pleo Import Buffer";
        NextEntryNo: Integer;
    begin
        Setup.GetSetup();
        TempPreview.Reset();
        TempPreview.DeleteAll();
        Buffer.Copy(BufferParam);
        Buffer.SetRange(Status, Buffer.Status::Validated);
        if not Buffer.FindSet() then
            exit;
        repeat
            NextEntryNo += 1;
            AddPreviewLine(Buffer, TempPreview, NextEntryNo);
        until Buffer.Next() = 0;
    end;

    local procedure AddPreviewLine(var Buffer: Record "BeDyn Pleo Import Buffer"; var TempPreview: Record "BeDyn Pleo Posting Preview" temporary; EntryNo: Integer)
    var
        Vendor: Record Vendor;
        InvoiceLbl: Label 'Factura de compra';
        CrMemoLbl: Label 'Abono de compra';
        ExtraLbl: Label 'Diario gasto extraordinario';
        WalletLbl: Label 'Diario recarga monedero';
        CashbackLbl: Label 'Diario cashback';
        GLKindLbl: Label 'Cuenta';
        FAKindLbl: Label 'Activo fijo';
        BankKindLbl: Label 'Banco';
        DraftActionLbl: Label 'Crear borrador';
        PostActionLbl: Label 'Registrar';
        PostPayActionLbl: Label 'Registrar y pagar (banco %1)', Comment = '%1 = banco Pleo';
        JournalActionLbl: Label 'Diario contra banco Pleo %1', Comment = '%1 = banco Pleo';
        ExtraDescLbl: Label 'Gasto extraordinario Pleo %1 %2', Comment = '%1 = nº recibo, %2 = comercio';
        WalletDescLbl: Label 'Recarga monedero Pleo %1', Comment = '%1 = nº recibo';
        CashbackDescLbl: Label 'Cashback Pleo %1', Comment = '%1 = nº recibo';
    begin
        TempPreview.Init();
        TempPreview."Entry No." := EntryNo;
        TempPreview."Buffer Entry No." := Buffer."Entry No.";
        TempPreview."Receipt No." := Buffer."Receipt No.";
        TempPreview."Posting Date" := Buffer."Expense Date";
        TempPreview.Amount := Abs(Buffer.Amount);
        TempPreview."External Doc. No." := CopyStr(Setup."Vendor Invoice No. Prefix" + Buffer."Receipt No.", 1, MaxStrLen(TempPreview."External Doc. No."));
        TempPreview."Project Code" := Buffer."Project Code";
        TempPreview."Job Task No." := Buffer."Job Task No.";
        TempPreview."Purchaser Code" := Buffer."Purchaser Code";
        TempPreview.Warning := Buffer."Warning Message";

        case Buffer."Expense Type" of
            Buffer."Expense Type"::"Card Purchase":
                if Buffer.Extraordinary then begin
                    TempPreview.Operation := ExtraLbl;
                    TempPreview."Account Kind" := GLKindLbl;
                    TempPreview."Account No." := Buffer."G/L Account No.";
                    TempPreview.Description := CopyStr(StrSubstNo(ExtraDescLbl, Buffer."Receipt No.", Buffer."Source Description"), 1, MaxStrLen(TempPreview.Description));
                    TempPreview."Action Text" := CopyStr(StrSubstNo(JournalActionLbl, Setup."Pleo Bank Account No."), 1, MaxStrLen(TempPreview."Action Text"));
                end else begin
                    if Buffer.Amount < 0 then
                        TempPreview.Operation := InvoiceLbl
                    else
                        TempPreview.Operation := CrMemoLbl;
                    TempPreview."Vendor No." := Buffer."Mapped Vendor No.";
                    if Vendor.Get(Buffer."Mapped Vendor No.") then
                        TempPreview."Vendor Name" := Vendor.Name;
                    if Buffer."Fixed Asset No." <> '' then begin
                        TempPreview."Account Kind" := FAKindLbl;
                        TempPreview."Account No." := Buffer."Fixed Asset No.";
                    end else begin
                        TempPreview."Account Kind" := GLKindLbl;
                        TempPreview."Account No." := Buffer."G/L Account No.";
                    end;
                    TempPreview.Description := BuildLineDescription(Buffer);
                    TempPreview."VAT Prod. Posting Group" := Setup."VAT Prod. Posting Group";
                    case Setup."Post Action" of
                        Setup."Post Action"::"Draft Only":
                            TempPreview."Action Text" := DraftActionLbl;
                        Setup."Post Action"::Post:
                            TempPreview."Action Text" := PostActionLbl;
                        Setup."Post Action"::"Post & Pay":
                            TempPreview."Action Text" := CopyStr(StrSubstNo(PostPayActionLbl, Setup."Pleo Bank Account No."), 1, MaxStrLen(TempPreview."Action Text"));
                    end;
                end;
            Buffer."Expense Type"::"Wallet Load":
                begin
                    TempPreview.Operation := WalletLbl;
                    TempPreview."Account Kind" := BankKindLbl;
                    TempPreview."Account No." := Setup."Wallet Origin Bank Account";
                    TempPreview.Description := CopyStr(StrSubstNo(WalletDescLbl, Buffer."Receipt No."), 1, MaxStrLen(TempPreview.Description));
                    TempPreview."Action Text" := CopyStr(StrSubstNo(JournalActionLbl, Setup."Pleo Bank Account No."), 1, MaxStrLen(TempPreview."Action Text"));
                end;
            Buffer."Expense Type"::Cashback:
                begin
                    TempPreview.Operation := CashbackLbl;
                    TempPreview."Account Kind" := GLKindLbl;
                    TempPreview."Account No." := Setup."Cashback G/L Account No.";
                    TempPreview.Description := CopyStr(StrSubstNo(CashbackDescLbl, Buffer."Receipt No."), 1, MaxStrLen(TempPreview.Description));
                    TempPreview."Action Text" := CopyStr(StrSubstNo(JournalActionLbl, Setup."Pleo Bank Account No."), 1, MaxStrLen(TempPreview."Action Text"));
                end;
        end;

        TempPreview.Insert();
    end;

    local procedure ProcessLine(var Buffer: Record "BeDyn Pleo Import Buffer"): Boolean
    begin
        case Buffer."Expense Type" of
            Buffer."Expense Type"::"Card Purchase":
                if Buffer.Extraordinary then
                    exit(PostExtraordinaryExpense(Buffer))
                else
                    exit(ProcessCardPurchase(Buffer));
            Buffer."Expense Type"::"Wallet Load":
                exit(PostBankJournal(Buffer, false));
            Buffer."Expense Type"::Cashback:
                exit(PostBankJournal(Buffer, true));
        end;
        exit(false);
    end;

    // ============================ COMPRAS TARJETA ============================

    local procedure ProcessCardPurchase(var Buffer: Record "BeDyn Pleo Import Buffer"): Boolean
    var
        PurchHeader: Record "Purchase Header";
        DocType: Enum "Purchase Document Type";
        PostedDocNo: Code[20];
        PostErr: Label 'Error al registrar: %1', Comment = '%1 = error';
        PayAfterPostErr: Label 'Documento %1 registrado, pero el pago falló: %2', Comment = '%1 = nº documento, %2 = error';
    begin
        if Buffer.Amount < 0 then
            DocType := DocType::Invoice
        else
            DocType := DocType::"Credit Memo";

        // Si la factura ya quedó registrada en un intento anterior (falló solo el
        // pago), no volver a crearla: reintentar únicamente el pago.
        if Buffer."Posted Document No." <> '' then
            exit(RetryPaymentOnly(Buffer, DocType));

        // Si quedó un borrador creado de un intento anterior, reutilizarlo.
        if (Buffer."Created Document No." = '') or (not PurchHeader.Get(DocType, Buffer."Created Document No.")) then begin
            if not CreateDocument(PurchHeader, DocType, Buffer) then begin
                CleanupHalfCreatedDoc(PurchHeader);
                Buffer.SetErrorState(GetLastErrorText());
                exit(false);
            end;
            Buffer.Status := Buffer.Status::Created;
            Buffer."Created Document No." := PurchHeader."No.";
            Buffer."Error Message" := '';
            Buffer.Modify(true);
        end;

        if Setup."Post Action" = Setup."Post Action"::"Draft Only" then
            exit(true);

        if not PostDocument(PurchHeader, PostedDocNo) then begin
            Buffer.SetErrorState(StrSubstNo(PostErr, GetLastErrorText()));
            exit(false);
        end;
        Buffer.Status := Buffer.Status::Posted;
        Buffer."Posted Document No." := PostedDocNo;
        Buffer.Modify(true);

        if Setup."Post Action" <> Setup."Post Action"::"Post & Pay" then
            exit(true);

        Commit();
        if not TryPostPayment(Buffer, DocType, PostedDocNo) then begin
            Buffer.SetErrorState(StrSubstNo(PayAfterPostErr, PostedDocNo, GetLastErrorText()));
            exit(false);
        end;
        Buffer.Status := Buffer.Status::Paid;
        Buffer."Payment Posted" := true;
        Buffer."Error Message" := '';
        Buffer.Modify(true);
        exit(true);
    end;

    local procedure RetryPaymentOnly(var Buffer: Record "BeDyn Pleo Import Buffer"; DocType: Enum "Purchase Document Type"): Boolean
    var
        PayErr: Label 'El pago del documento %1 falló: %2', Comment = '%1 = nº documento, %2 = error';
    begin
        if Setup."Post Action" <> Setup."Post Action"::"Post & Pay" then begin
            Buffer.Status := Buffer.Status::Posted;
            Buffer.Modify(true);
            exit(true);
        end;
        Commit();
        if not TryPostPayment(Buffer, DocType, Buffer."Posted Document No.") then begin
            Buffer.SetErrorState(StrSubstNo(PayErr, Buffer."Posted Document No.", GetLastErrorText()));
            exit(false);
        end;
        Buffer.Status := Buffer.Status::Paid;
        Buffer."Payment Posted" := true;
        Buffer."Error Message" := '';
        Buffer.Modify(true);
        exit(true);
    end;

    [TryFunction]
    local procedure CreateDocument(var PurchHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; var Buffer: Record "BeDyn Pleo Import Buffer")
    var
        ExtDocNo: Code[35];
    begin
        ExtDocNo := CopyStr(Setup."Vendor Invoice No. Prefix" + Buffer."Receipt No.", 1, 35);

        PurchHeader.Init();
        PurchHeader."Document Type" := DocType;
        PurchHeader."No." := '';
        PurchHeader.Insert(true);

        PurchHeader.Validate("Buy-from Vendor No.", Buffer."Mapped Vendor No.");
        // Después de validar el proveedor, que trae su comprador por defecto:
        // el del mapeo de empleados de Pleo tiene prioridad.
        if Buffer."Purchaser Code" <> '' then
            PurchHeader.Validate("Purchaser Code", Buffer."Purchaser Code");
        PurchHeader.Validate("Document Date", Buffer."Expense Date");
        PurchHeader.Validate("Posting Date", Buffer."Expense Date");
        // Los importes de Pleo vienen con IVA incluido: BC calcula la base hacia atrás.
        PurchHeader.Validate("Prices Including VAT", true);
        if DocType = DocType::"Credit Memo" then
            PurchHeader.Validate("Vendor Cr. Memo No.", ExtDocNo)
        else
            PurchHeader.Validate("Vendor Invoice No.", ExtDocNo);
        ApplyHeaderDimensions(PurchHeader, Buffer);
        PurchHeader.Modify(true);

        CreateDocumentLine(PurchHeader, Buffer);
    end;

    local procedure CreateDocumentLine(var PurchHeader: Record "Purchase Header"; var Buffer: Record "BeDyn Pleo Import Buffer")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Init();
        PurchLine.Validate("Document Type", PurchHeader."Document Type");
        PurchLine.Validate("Document No.", PurchHeader."No.");
        PurchLine."Line No." := 10000;
        PurchLine.Insert(true);

        if Buffer."Fixed Asset No." <> '' then begin
            // CAPEX: adquisición de activo fijo (el activo viene resuelto por la propiedad).
            PurchLine.Validate(Type, PurchLine.Type::"Fixed Asset");
            PurchLine.Validate("No.", Buffer."Fixed Asset No.");
            PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::"Acquisition Cost");
            if Setup."FA Depreciation Book Code" <> '' then
                PurchLine.Validate("Depreciation Book Code", Setup."FA Depreciation Book Code");
        end else begin
            PurchLine.Validate(Type, PurchLine.Type::"G/L Account");
            PurchLine.Validate("No.", Buffer."G/L Account No.");
        end;
        PurchLine.Validate(Quantity, 1);

        // Grupo IVA único definido en la configuración: se fuerza en todas las líneas.
        if Setup."VAT Prod. Posting Group" <> '' then
            PurchLine.Validate("VAT Prod. Posting Group", Setup."VAT Prod. Posting Group");

        // Imputación a proyecto: el gasto se repercute a la tarea del proyecto de la
        // propiedad (resueltos en la validación). Solo líneas de cuenta contable:
        // las de activo fijo no admiten proyecto en la línea de compra.
        if (Buffer."Job No." <> '') and (Buffer."Job Task No." <> '') and (Buffer."Fixed Asset No." = '') then begin
            PurchLine.Validate("Job No.", Buffer."Job No.");
            PurchLine.Validate("Job Task No.", Buffer."Job Task No.");
        end;

        PurchLine.Validate("Direct Unit Cost", Abs(Buffer.Amount));
        PurchLine.Validate(Description, BuildLineDescription(Buffer));
        PurchLine.Modify(true);
    end;

    local procedure BuildLineDescription(Buffer: Record "BeDyn Pleo Import Buffer"): Text[100]
    var
        Desc: Text;
    begin
        Desc := Buffer."Source Description";
        if Buffer.Note <> '' then
            if Desc <> '' then
                Desc := Desc + ' - ' + Buffer.Note
            else
                Desc := Buffer.Note;
        if Desc = '' then
            Desc := 'Pleo ' + Buffer."Receipt No.";
        exit(CopyStr(Desc, 1, 100));
    end;

    // Dimensiones de la cabecera: valor de proyecto + dimensiones por defecto del
    // comprador mapeado. Las del comprador se fusionan siempre explícitamente para
    // garantizarlas aunque la validación estándar del campo no las arrastre.
    local procedure ApplyHeaderDimensions(var PurchHeader: Record "Purchase Header"; Buffer: Record "BeDyn Pleo Import Buffer")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        if (Setup."Project Dimension Code" <> '') and (Buffer."Project Code" <> '') then
            PurchHeader."Dimension Set ID" :=
                AddDimensionToSet(PurchHeader."Dimension Set ID", Setup."Project Dimension Code", Buffer."Project Code");
        PurchHeader."Dimension Set ID" :=
            AddPurchaserDefaultDims(PurchHeader."Dimension Set ID", Buffer."Purchaser Code");
        DimMgt.UpdateGlobalDimFromDimSetID(
            PurchHeader."Dimension Set ID",
            PurchHeader."Shortcut Dimension 1 Code",
            PurchHeader."Shortcut Dimension 2 Code");
    end;

    // Fusiona en el conjunto las dimensiones por defecto de la ficha del
    // comprador/vendedor (p.ej. la dimensión COMPRADOR).
    local procedure AddPurchaserDefaultDims(DimSetID: Integer; PurchaserCode: Code[20]): Integer
    var
        DefaultDim: Record "Default Dimension";
    begin
        if PurchaserCode = '' then
            exit(DimSetID);
        DefaultDim.SetRange("Table ID", Database::"Salesperson/Purchaser");
        DefaultDim.SetRange("No.", PurchaserCode);
        DefaultDim.SetFilter("Dimension Value Code", '<>%1', '');
        if DefaultDim.FindSet() then
            repeat
                DimSetID := AddDimensionToSet(DimSetID, DefaultDim."Dimension Code", DefaultDim."Dimension Value Code");
            until DefaultDim.Next() = 0;
        exit(DimSetID);
    end;

    local procedure AddDimensionToSet(DimSetID: Integer; DimCode: Code[20]; DimValueCode: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimValue: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
    begin
        DimValue.Get(DimCode, DimValueCode);
        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        TempDimSetEntry.SetRange("Dimension Code", DimCode);
        if TempDimSetEntry.FindFirst() then
            TempDimSetEntry.Delete();
        TempDimSetEntry.Reset();
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Set ID" := 0;
        TempDimSetEntry."Dimension Code" := DimCode;
        TempDimSetEntry."Dimension Value Code" := DimValueCode;
        TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
        TempDimSetEntry.Insert();
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure CleanupHalfCreatedDoc(var PurchHeader: Record "Purchase Header")
    begin
        // Un TryFunction no revierte escrituras: si la creación falló a medias,
        // eliminar el borrador incompleto para no dejar basura.
        if PurchHeader."No." = '' then
            exit;
        if PurchHeader.Find() then
            PurchHeader.Delete(true);
    end;

    local procedure PostDocument(var PurchHeader: Record "Purchase Header"; var PostedDocNo: Code[20]): Boolean
    var
        PurchPost: Codeunit "Purch.-Post";
        SavedWorkDate: Date;
        PostOk: Boolean;
    begin
        PurchHeader.Receive := false;
        PurchHeader.Invoice := true;
        PurchHeader.Ship := false;
        Commit();
        // Igualar temporalmente la fecha de trabajo a la de registro evita el aviso
        // "la fecha de registro es diferente de la fecha de trabajo".
        SavedWorkDate := WorkDate();
        if PurchHeader."Posting Date" <> 0D then
            WorkDate(PurchHeader."Posting Date");
        PostOk := PurchPost.Run(PurchHeader);
        WorkDate(SavedWorkDate);
        if not PostOk then
            exit(false);
        PostedDocNo := PurchHeader."Last Posting No.";
        if PostedDocNo = '' then
            PostedDocNo := PurchHeader."Posting No.";
        exit(true);
    end;

    // ============================ PAGO BANCO PLEO ============================

    [TryFunction]
    local procedure TryPostPayment(var Buffer: Record "BeDyn Pleo Import Buffer"; DocType: Enum "Purchase Document Type"; PostedDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        PayDescLbl: Label 'Pago Pleo %1 %2', Comment = '%1 = nº recibo, %2 = comercio';
    begin
        VendLedgEntry.SetRange("Vendor No.", Buffer."Mapped Vendor No.");
        if DocType = DocType::"Credit Memo" then
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo")
        else
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange("Document No.", PostedDocNo);
        VendLedgEntry.FindFirst();
        VendLedgEntry.CalcFields("Remaining Amount");
        if VendLedgEntry."Remaining Amount" = 0 then
            exit; // ya liquidada (p.ej. reintento tras un pago que sí llegó a registrarse)

        GenJnlLine.Init();
        if DocType = DocType::"Credit Memo" then
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund
        else
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := PostedDocNo;
        GenJnlLine.Validate("Posting Date", Buffer."Expense Date");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.Validate("Account No.", Buffer."Mapped Vendor No.");
        GenJnlLine.Validate(Amount, -VendLedgEntry."Remaining Amount");
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", Setup."Pleo Bank Account No.");
        GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
        GenJnlLine."Applies-to Doc. No." := PostedDocNo;
        GenJnlLine."External Document No." := CopyStr(Setup."Vendor Invoice No. Prefix" + Buffer."Receipt No.", 1, MaxStrLen(GenJnlLine."External Document No."));
        GenJnlLine.Description := CopyStr(StrSubstNo(PayDescLbl, Buffer."Receipt No.", Buffer."Source Description"), 1, MaxStrLen(GenJnlLine.Description));
        // El pago hereda las dimensiones de la factura (proyecto incluido) y se le
        // garantiza además la dimensión del comprador y el propio código de comprador.
        GenJnlLine."Salespers./Purch. Code" := Buffer."Purchaser Code";
        GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        GenJnlLine."Dimension Set ID" :=
            AddPurchaserDefaultDims(GenJnlLine."Dimension Set ID", Buffer."Purchaser Code");
        DimMgt.UpdateGlobalDimFromDimSetID(
            GenJnlLine."Dimension Set ID",
            GenJnlLine."Shortcut Dimension 1 Code",
            GenJnlLine."Shortcut Dimension 2 Code");
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    // ======================== GASTOS EXTRAORDINARIOS =========================
    // Empleado "No deducible" sin justificante: diario directo del banco Pleo a la
    // cuenta de gastos extraordinarios, sin IVA y sin factura de proveedor.

    local procedure PostExtraordinaryExpense(var Buffer: Record "BeDyn Pleo Import Buffer"): Boolean
    var
        JnlErr: Label 'Error al registrar el gasto extraordinario: %1', Comment = '%1 = error';
    begin
        Commit();
        if not TryPostExtraordinaryJournal(Buffer) then begin
            Buffer.SetErrorState(StrSubstNo(JnlErr, GetLastErrorText()));
            exit(false);
        end;
        Buffer.Status := Buffer.Status::Posted;
        Buffer."Posted Document No." := CopyStr(Setup."Vendor Invoice No. Prefix" + Buffer."Receipt No.", 1, 20);
        Buffer."Error Message" := '';
        Buffer.Modify(true);
        exit(true);
    end;

    [TryFunction]
    local procedure TryPostExtraordinaryJournal(var Buffer: Record "BeDyn Pleo Import Buffer")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        ExtraDescLbl: Label 'Gasto extraordinario Pleo %1 %2', Comment = '%1 = nº recibo, %2 = comercio';
    begin
        GenJnlLine.Init();
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := CopyStr(Setup."Vendor Invoice No. Prefix" + Buffer."Receipt No.", 1, 20);
        GenJnlLine.Validate("Posting Date", Buffer."Expense Date");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
        GenJnlLine.Validate("Account No.", Setup."Pleo Bank Account No.");
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", Buffer."G/L Account No.");
        // Sin IVA: se limpia la configuración de registro que arrastra la cuenta.
        GenJnlLine."Bal. Gen. Posting Type" := GenJnlLine."Bal. Gen. Posting Type"::" ";
        GenJnlLine."Bal. Gen. Bus. Posting Group" := '';
        GenJnlLine."Bal. Gen. Prod. Posting Group" := '';
        GenJnlLine."Bal. VAT Bus. Posting Group" := '';
        GenJnlLine."Bal. VAT Prod. Posting Group" := '';
        GenJnlLine.Validate(Amount, Buffer.Amount);
        GenJnlLine."External Document No." := CopyStr(Setup."Vendor Invoice No. Prefix" + Buffer."Receipt No.", 1, MaxStrLen(GenJnlLine."External Document No."));
        GenJnlLine.Description := CopyStr(StrSubstNo(ExtraDescLbl, Buffer."Receipt No.", Buffer."Source Description"), 1, MaxStrLen(GenJnlLine.Description));
        if Buffer."Purchaser Code" <> '' then
            GenJnlLine.Validate("Salespers./Purch. Code", Buffer."Purchaser Code");
        // El diario lleva la dimensión de proyecto y, siempre, las dimensiones por
        // defecto del comprador (clave en los gastos no deducibles, que no generan
        // documento de compra que las arrastre).
        if (Setup."Project Dimension Code" <> '') and (Buffer."Project Code" <> '') then
            GenJnlLine."Dimension Set ID" :=
                AddDimensionToSet(GenJnlLine."Dimension Set ID", Setup."Project Dimension Code", Buffer."Project Code");
        GenJnlLine."Dimension Set ID" :=
            AddPurchaserDefaultDims(GenJnlLine."Dimension Set ID", Buffer."Purchaser Code");
        DimMgt.UpdateGlobalDimFromDimSetID(
            GenJnlLine."Dimension Set ID",
            GenJnlLine."Shortcut Dimension 1 Code",
            GenJnlLine."Shortcut Dimension 2 Code");
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    // ====================== RECARGAS MONEDERO / CASHBACK ======================

    local procedure PostBankJournal(var Buffer: Record "BeDyn Pleo Import Buffer"; IsCashback: Boolean): Boolean
    var
        JnlErr: Label 'Error al registrar el diario: %1', Comment = '%1 = error';
    begin
        Commit();
        if not TryPostBankJournal(Buffer, IsCashback) then begin
            Buffer.SetErrorState(StrSubstNo(JnlErr, GetLastErrorText()));
            exit(false);
        end;
        Buffer.Status := Buffer.Status::Posted;
        Buffer."Posted Document No." := CopyStr(Setup."Vendor Invoice No. Prefix" + Buffer."Receipt No.", 1, 20);
        Buffer."Error Message" := '';
        Buffer.Modify(true);
        exit(true);
    end;

    [TryFunction]
    local procedure TryPostBankJournal(var Buffer: Record "BeDyn Pleo Import Buffer"; IsCashback: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        WalletDescLbl: Label 'Recarga monedero Pleo %1', Comment = '%1 = nº recibo';
        CashbackDescLbl: Label 'Cashback Pleo %1', Comment = '%1 = nº recibo';
    begin
        GenJnlLine.Init();
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := CopyStr(Setup."Vendor Invoice No. Prefix" + Buffer."Receipt No.", 1, 20);
        GenJnlLine.Validate("Posting Date", Buffer."Expense Date");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
        GenJnlLine.Validate("Account No.", Setup."Pleo Bank Account No.");
        GenJnlLine.Validate(Amount, Buffer.Amount);
        if IsCashback then begin
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
            GenJnlLine.Validate("Bal. Account No.", Setup."Cashback G/L Account No.");
            GenJnlLine.Description := CopyStr(StrSubstNo(CashbackDescLbl, Buffer."Receipt No."), 1, MaxStrLen(GenJnlLine.Description));
        end else begin
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
            GenJnlLine.Validate("Bal. Account No.", Setup."Wallet Origin Bank Account");
            GenJnlLine.Description := CopyStr(StrSubstNo(WalletDescLbl, Buffer."Receipt No."), 1, MaxStrLen(GenJnlLine.Description));
        end;
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;
}
