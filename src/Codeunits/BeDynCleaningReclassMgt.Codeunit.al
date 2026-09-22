namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Purchases.History;

codeunit 82702 "BeDyn Cleaning Reclass Mgt."
{
    // Marcar la factura registrada como dimensionada exige modificar la cabecera
    // histórica (tabla 122), que las licencias no conceden en directo. Igual que
    // el codeunit estándar "Purch. Inv. Header - Edit", el permiso se eleva aquí
    // a nivel de objeto.
    Permissions = tabledata "Purch. Inv. Header" = rm;

    // Genera el diario de reclasificación del gasto de limpiezas: abona la cuenta
    // puente (donde se registró la factura global del proveedor) y carga las
    // cuentas de gasto reales con proyecto, tarea, dimensión de propiedad y
    // cantidad (horas/kg/kits).
    //
    // Se procesa factura a factura: para cada factura de la selección se toman
    // TODAS sus líneas validadas y se exige que, junto con las ya reclasificadas,
    // cubran la base imponible de la factura dentro de la tolerancia configurada.
    // El nº de documento del diario es el nº de la factura y la fecha de registro
    // el último día del mes del servicio más reciente.

    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";

    // ============================ ASIGNAR FACTURA ============================

    // Asigna una factura registrada a las líneas seleccionadas. El lookup se
    // filtra por el proveedor de las líneas, que debe ser único en la selección.
    procedure AssignInvoice(var ImportLineParam: Record "BeDyn Cleaning Import Line")
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        AssignedCount: Integer;
        NothingMsg: Label 'No hay líneas sin reclasificar en la selección.';
        MixedVendorsErr: Label 'La selección contiene líneas de varios proveedores (%1 y %2). Asigna las facturas proveedor a proveedor.', Comment = '%1, %2 = proveedores';
        AssignedMsg: Label 'Factura %1 asignada a %2 líneas.', Comment = '%1 = factura, %2 = nº líneas';
    begin
        ImportLine.Copy(ImportLineParam);
        ImportLine.SetFilter(Status, '<>%1', ImportLine.Status::Posted);
        if not ImportLine.FindSet() then begin
            Message(NothingMsg);
            exit;
        end;
        repeat
            if (VendorNo <> '') and (ImportLine."Vendor No." <> VendorNo) then
                Error(MixedVendorsErr, VendorNo, ImportLine."Vendor No.");
            VendorNo := ImportLine."Vendor No.";
        until ImportLine.Next() = 0;

        if VendorNo <> '' then
            PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("BeDyn Dimensioned", false);
        if Page.RunModal(Page::"Posted Purchase Invoices", PurchInvHeader) <> Action::LookupOK then
            exit;

        ImportLine.FindSet(true);
        repeat
            ImportLine.Validate("Invoice No.", PurchInvHeader."No.");
            ImportLine.Modify(true);
            AssignedCount += 1;
        until ImportLine.Next() = 0;
        Message(AssignedMsg, PurchInvHeader."No.", AssignedCount);
    end;

    // ============================ CUADRE ============================

    // Importes de una factura frente al staging: asignado (cualquier estado) y ya
    // reclasificado. La base imponible sale de la propia factura registrada.
    procedure GetInvoiceCoverage(InvoiceNo: Code[20]; var BaseAmount: Decimal; var AssignedAmount: Decimal; var PostedAmount: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        ImportLine: Record "BeDyn Cleaning Import Line";
    begin
        BaseAmount := 0;
        if PurchInvHeader.Get(InvoiceNo) then begin
            PurchInvHeader.CalcFields(Amount);
            BaseAmount := PurchInvHeader.Amount;
        end;

        ImportLine.SetCurrentKey("Invoice No.", Status);
        ImportLine.SetRange("Invoice No.", InvoiceNo);
        ImportLine.CalcSums(Amount);
        AssignedAmount := ImportLine.Amount;

        ImportLine.SetRange(Status, ImportLine.Status::Posted);
        ImportLine.CalcSums(Amount);
        PostedAmount := ImportLine.Amount;
    end;

    // Muestra el cuadre de las facturas presentes en la selección, cualquiera
    // que sea el estado de las líneas: el cuadre se puede comprobar antes de
    // validar.
    procedure ShowMatchStatus(var ImportLineParam: Record "BeDyn Cleaning Import Line")
    var
        InvoiceList: List of [Code[20]];
        InvoiceNo: Code[20];
        BaseAmount: Decimal;
        AssignedAmount: Decimal;
        PostedAmount: Decimal;
        MsgText: TextBuilder;
        NoInvoiceMsg: Label 'La selección no tiene ninguna factura asignada.';
        CoverageLbl: Label 'Factura %1: base %2, asignado %3 (reclasificado %4), diferencia %5.', Comment = '%1 = factura, %2..%5 = importes';
    begin
        CollectInvoices(ImportLineParam, InvoiceList, false);
        if InvoiceList.Count() = 0 then begin
            Message(NoInvoiceMsg);
            exit;
        end;
        foreach InvoiceNo in InvoiceList do begin
            GetInvoiceCoverage(InvoiceNo, BaseAmount, AssignedAmount, PostedAmount);
            if MsgText.Length() > 0 then
                MsgText.AppendLine();
            MsgText.AppendLine(StrSubstNo(CoverageLbl, InvoiceNo, Format(BaseAmount), Format(AssignedAmount), Format(PostedAmount), Format(BaseAmount - AssignedAmount)));
        end;
        Message(MsgText.ToText());
    end;

    // ============================ RECLASIFICACIÓN ============================

    procedure GenerateReclass(var ImportLineParam: Record "BeDyn Cleaning Import Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        InvoiceList: List of [Code[20]];
        InvoiceNo: Code[20];
        LastLineNo: Integer;
        TotalLines: Integer;
        NothingMsg: Label 'No hay líneas validadas con factura asignada en la selección.';
        UnassignedErr: Label 'Hay %1 líneas validadas sin factura asignada en la selección. Asigna la factura antes de reclasificar.', Comment = '%1 = nº líneas';
        BatchNotEmptyErr: Label 'La sección de diario %1/%2 contiene otras líneas y el registro automático está activado. Vacíala o usa una sección dedicada.', Comment = '%1 = libro, %2 = sección';
        OpenJnlQst: Label 'Diario de reclasificación generado en %1/%2 (%3 líneas). ¿Quieres abrirlo ahora para revisarlo y registrarlo?', Comment = '%1 = libro, %2 = sección, %3 = nº líneas';
        PostedMsg: Label 'Reclasificación registrada (%1 líneas de diario).', Comment = '%1 = nº líneas';
    begin
        PropertySetup.GetInstance();
        PropertySetup.TestField("Cleaning Bridge Account No.");
        PropertySetup.TestField("Cleaning Jnl. Template Name");
        PropertySetup.TestField("Cleaning Jnl. Batch Name");
        GenJnlBatch.Get(PropertySetup."Cleaning Jnl. Template Name", PropertySetup."Cleaning Jnl. Batch Name");

        CheckSelection(ImportLineParam, InvoiceList, UnassignedErr, NothingMsg);

        if PropertySetup."Cleaning Auto Post Reclass" and BatchHasOtherLines() then
            Error(BatchNotEmptyErr, PropertySetup."Cleaning Jnl. Template Name", PropertySetup."Cleaning Jnl. Batch Name");

        LastLineNo := GetLastJournalLineNo();
        foreach InvoiceNo in InvoiceList do
            TotalLines += CreateInvoiceReclass(InvoiceNo, LastLineNo);

        if PropertySetup."Cleaning Auto Post Reclass" then begin
            PostBatch();
            Message(PostedMsg, TotalLines);
        end else
            // Ofrecer abrir el diario donde ha quedado el asiento, ya posicionado
            // en el libro y sección de la configuración.
            if Confirm(StrSubstNo(OpenJnlQst, PropertySetup."Cleaning Jnl. Template Name", PropertySetup."Cleaning Jnl. Batch Name", TotalLines), true) then
                GenJnlManagement.TemplateSelectionFromBatch(GenJnlBatch);
    end;

    local procedure CheckSelection(var ImportLineParam: Record "BeDyn Cleaning Import Line"; var InvoiceList: List of [Code[20]]; UnassignedErr: Text; NothingMsg: Text)
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
        UnassignedCount: Integer;
    begin
        ImportLine.Copy(ImportLineParam);
        ImportLine.SetRange(Status, ImportLine.Status::Validated);
        ImportLine.SetRange("Invoice No.", '');
        UnassignedCount := ImportLine.Count();
        if UnassignedCount > 0 then
            Error(UnassignedErr, UnassignedCount);

        CollectInvoices(ImportLineParam, InvoiceList, true);
        if InvoiceList.Count() = 0 then
            Error(NothingMsg);
    end;

    // Facturas presentes en la selección. Con OnlyValidated, solo las de líneas
    // validadas (las únicas que la reclasificación procesa).
    local procedure CollectInvoices(var ImportLineParam: Record "BeDyn Cleaning Import Line"; var InvoiceList: List of [Code[20]]; OnlyValidated: Boolean)
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
    begin
        Clear(InvoiceList);
        ImportLine.Copy(ImportLineParam);
        if OnlyValidated then
            ImportLine.SetRange(Status, ImportLine.Status::Validated);
        ImportLine.SetFilter("Invoice No.", '<>%1', '');
        if not ImportLine.FindSet() then
            exit;
        repeat
            if not InvoiceList.Contains(ImportLine."Invoice No.") then
                InvoiceList.Add(ImportLine."Invoice No.");
        until ImportLine.Next() = 0;
    end;

    // Reclasifica una factura completa: comprueba el cuadre contra su base
    // imponible, genera las líneas de gasto (agregadas o detalladas según la
    // configuración) y el abono a la cuenta puente, y marca el staging.
    // Devuelve el nº de líneas de diario creadas.
    local procedure CreateInvoiceReclass(InvoiceNo: Code[20]; var LastLineNo: Integer): Integer
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
        BaseAmount: Decimal;
        AssignedAmount: Decimal;
        PostedAmount: Decimal;
        Tolerance: Decimal;
        PostingDate: Date;
        TotalAmount: Decimal;
        LineCount: Integer;
        MatchErr: Label 'La factura %1 no cuadra: base imponible %2, líneas validadas + reclasificadas %3 (diferencia %4, tolerancia %5). Completa o corrige las líneas antes de reclasificar.', Comment = '%1 = factura, %2..%5 = importes';
    begin
        // Cuadre: validadas + ya reclasificadas deben cubrir la base de la factura.
        GetInvoiceCoverage(InvoiceNo, BaseAmount, AssignedAmount, PostedAmount);
        ImportLine.SetCurrentKey("Invoice No.", Status);
        ImportLine.SetRange("Invoice No.", InvoiceNo);
        ImportLine.SetRange(Status, ImportLine.Status::Validated);
        ImportLine.CalcSums(Amount);
        Tolerance := PropertySetup."Cleaning Match Tolerance";
        if Abs(BaseAmount - (ImportLine.Amount + PostedAmount)) > Tolerance then
            Error(MatchErr, InvoiceNo, Format(BaseAmount), Format(ImportLine.Amount + PostedAmount), Format(BaseAmount - (ImportLine.Amount + PostedAmount)), Format(Tolerance));

        // Fecha de registro única para el documento: fin del mes del último servicio.
        ImportLine.SetCurrentKey("Invoice No.", "Job No.", "Service Code", "Service Date");
        PostingDate := CalcDate('<CM>', GetMaxServiceDate(ImportLine));

        ImportLine.FindSet(true);
        if PropertySetup."Cleaning Posting Mode" = PropertySetup."Cleaning Posting Mode"::Detailed then
            LineCount := CreateDetailedLines(ImportLine, InvoiceNo, PostingDate, LastLineNo, TotalAmount)
        else
            LineCount := CreateAggregatedLines(ImportLine, InvoiceNo, PostingDate, LastLineNo, TotalAmount);

        CreateBridgeCreditLine(InvoiceNo, PostingDate, TotalAmount, LastLineNo);
        MarkInvoiceDimensioned(InvoiceNo);
        exit(LineCount + 1);
    end;

    // Marca la factura registrada como dimensionada: la validación rechaza
    // nuevas líneas contra una factura ya reclasificada.
    local procedure MarkInvoiceDimensioned(InvoiceNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if not PurchInvHeader.Get(InvoiceNo) then
            exit;
        PurchInvHeader."BeDyn Dimensioned" := true;
        PurchInvHeader.Modify();
    end;

    // Modo detallado: una línea de diario por línea de staging, con su fecha de
    // servicio en la descripción.
    local procedure CreateDetailedLines(var ImportLine: Record "BeDyn Cleaning Import Line"; InvoiceNo: Code[20]; PostingDate: Date; var LastLineNo: Integer; var TotalAmount: Decimal) LineCount: Integer
    var
        ServiceName: Text;
        UnitText: Text;
        DetailDescLbl: Label '%1 %2 %3 (%4 %5)', Comment = '%1 = servicio, %2 = fecha, %3 = propiedad, %4 = cantidad, %5 = unidad', Locked = true;
    begin
        repeat
            GetServiceInfo(ImportLine, ServiceName, UnitText);
            CreateExpenseJnlLine(
                ImportLine, PostingDate, InvoiceNo, ImportLine.Amount, ImportLine.Quantity,
                StrSubstNo(DetailDescLbl, ServiceName, Format(ImportLine."Service Date"), ImportLine."Job No.", Format(ImportLine.Quantity), UnitText),
                LastLineNo);
            TotalAmount += ImportLine.Amount;
            LineCount += 1;
            MarkLinePosted(ImportLine, InvoiceNo, PostingDate);
        until ImportLine.Next() = 0;
    end;

    // Modo agregado: una línea de diario por propiedad + servicio + mes. Las
    // líneas llegan ordenadas por la clave (factura, proyecto, servicio, fecha).
    local procedure CreateAggregatedLines(var ImportLine: Record "BeDyn Cleaning Import Line"; InvoiceNo: Code[20]; PostingDate: Date; var LastLineNo: Integer; var TotalAmount: Decimal) LineCount: Integer
    var
        GroupLine: Record "BeDyn Cleaning Import Line";
        GroupAmount: Decimal;
        GroupQty: Decimal;
        HasGroup: Boolean;
    begin
        repeat
            // Ifs anidados a propósito: AL no cortocircuita el "and", y SameGroup
            // no debe evaluarse en la primera vuelta con GroupLine sin inicializar
            // (Date2DMY sobre fecha vacía da "La fecha no es válida").
            if HasGroup then
                if not SameGroup(GroupLine, ImportLine) then begin
                    CreateGroupJnlLine(GroupLine, InvoiceNo, PostingDate, GroupAmount, GroupQty, LastLineNo);
                    LineCount += 1;
                    GroupAmount := 0;
                    GroupQty := 0;
                end;
            GroupLine := ImportLine;
            HasGroup := true;
            GroupAmount += ImportLine.Amount;
            GroupQty += ImportLine.Quantity;
            TotalAmount += ImportLine.Amount;
            MarkLinePosted(ImportLine, InvoiceNo, PostingDate);
        until ImportLine.Next() = 0;

        if HasGroup then begin
            CreateGroupJnlLine(GroupLine, InvoiceNo, PostingDate, GroupAmount, GroupQty, LastLineNo);
            LineCount += 1;
        end;
    end;

    local procedure GetMaxServiceDate(var ImportLineParam: Record "BeDyn Cleaning Import Line") MaxDate: Date
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
        NoDateErr: Label 'La línea %1 (fila CSV %2) de la factura %3 no tiene fecha de servicio. Corrígela y vuelve a validar antes de reclasificar.', Comment = '%1 = nº movimiento, %2 = fila CSV, %3 = factura';
    begin
        ImportLine.Copy(ImportLineParam);
        ImportLine.FindSet();
        repeat
            if ImportLine."Service Date" = 0D then
                Error(NoDateErr, ImportLine."Entry No.", ImportLine."Row No.", ImportLine."Invoice No.");
            if ImportLine."Service Date" > MaxDate then
                MaxDate := ImportLine."Service Date";
        until ImportLine.Next() = 0;
    end;

    local procedure SameGroup(GroupLine: Record "BeDyn Cleaning Import Line"; ImportLine: Record "BeDyn Cleaning Import Line"): Boolean
    begin
        exit(
            (GroupLine."Job No." = ImportLine."Job No.") and
            (GroupLine."Service Code" = ImportLine."Service Code") and
            (Date2DMY(GroupLine."Service Date", 3) = Date2DMY(ImportLine."Service Date", 3)) and
            (Date2DMY(GroupLine."Service Date", 2) = Date2DMY(ImportLine."Service Date", 2)));
    end;

    local procedure CreateGroupJnlLine(GroupLine: Record "BeDyn Cleaning Import Line"; InvoiceNo: Code[20]; PostingDate: Date; GroupAmount: Decimal; GroupQty: Decimal; var LastLineNo: Integer)
    var
        ServiceName: Text;
        UnitText: Text;
        GroupDescLbl: Label '%1 %2 %3 (%4 %5)', Comment = '%1 = servicio, %2 = mes, %3 = propiedad, %4 = cantidad, %5 = unidad', Locked = true;
    begin
        GetServiceInfo(GroupLine, ServiceName, UnitText);
        CreateExpenseJnlLine(
            GroupLine, PostingDate, InvoiceNo, GroupAmount, GroupQty,
            StrSubstNo(
                GroupDescLbl, ServiceName, Format(GroupLine."Service Date", 0, '<Month,2>/<Year4>'),
                GroupLine."Job No.", Format(GroupQty), UnitText),
            LastLineNo);
    end;

    // Línea de gasto del diario: cuenta real del servicio, proyecto, tarea y
    // cantidad. Sin IVA (es una reclasificación entre cuentas: el IVA ya se
    // registró con la factura). A las dimensiones por defecto del proyecto se
    // suman las de la propiedad o las de su producto (según el parámetro
    // "Trabajar con" de la configuración) y las del servicio de la tabla de
    // servicios.
    local procedure CreateExpenseJnlLine(ImportLine: Record "BeDyn Cleaning Import Line"; PostingDate: Date; InvoiceNo: Code[20]; LineAmount: Decimal; LineQty: Decimal; Description: Text; var LastLineNo: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
        PropertyDimMgt: Codeunit "BeDyn Property Dimension Mgt.";
        DimMgt: Codeunit DimensionManagement;
    begin
        InitJnlLine(GenJnlLine, PostingDate, InvoiceNo, LastLineNo);
        GenJnlLine.Validate("Account No.", ImportLine."G/L Account No.");
        ClearVATPosting(GenJnlLine);
        GenJnlLine.Validate("Job No.", ImportLine."Job No.");
        GenJnlLine.Validate("Job Task No.", ImportLine."Job Task No.");
        GenJnlLine.Validate(Amount, LineAmount);
        GenJnlLine.Validate("Job Quantity", LineQty);
        GenJnlLine.Description := CopyStr(Description, 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine."Dimension Set ID" :=
            PropertyDimMgt.AddPropertyDefaultDims(GenJnlLine."Dimension Set ID", ImportLine."Property Code");
        GenJnlLine."Dimension Set ID" :=
            PropertyDimMgt.AddServiceDefaultDims(GenJnlLine."Dimension Set ID", ImportLine."Service Code");
        DimMgt.UpdateGlobalDimFromDimSetID(
            GenJnlLine."Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code");
        GenJnlLine.Modify(true);
    end;

    // Abono a la cuenta puente por el total de la factura reclasificada: la deja
    // a cero si la factura se registró en ella por su base imponible.
    local procedure CreateBridgeCreditLine(InvoiceNo: Code[20]; PostingDate: Date; TotalAmount: Decimal; var LastLineNo: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CreditDescLbl: Label 'Reclasificación fra. %1 servicios limpieza', Comment = '%1 = nº factura';
    begin
        InitJnlLine(GenJnlLine, PostingDate, InvoiceNo, LastLineNo);
        GenJnlLine.Validate("Account No.", PropertySetup."Cleaning Bridge Account No.");
        ClearVATPosting(GenJnlLine);
        GenJnlLine.Validate(Amount, -TotalAmount);
        GenJnlLine.Description := CopyStr(StrSubstNo(CreditDescLbl, InvoiceNo), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Modify(true);
    end;

    local procedure InitJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date; InvoiceNo: Code[20]; var LastLineNo: Integer)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Get(PropertySetup."Cleaning Jnl. Template Name");
        LastLineNo += 10000;
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := PropertySetup."Cleaning Jnl. Template Name";
        GenJnlLine."Journal Batch Name" := PropertySetup."Cleaning Jnl. Batch Name";
        GenJnlLine."Line No." := LastLineNo;
        GenJnlLine.Insert(true);
        GenJnlLine."Source Code" := GenJnlTemplate."Source Code";
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := InvoiceNo;
        GenJnlLine."External Document No." := InvoiceNo;
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
    end;

    // Reclasificación sin IVA: se limpia la configuración de registro que arrastra
    // la cuenta para que no se calcule impuesto ninguno.
    local procedure ClearVATPosting(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
        GenJnlLine."Gen. Bus. Posting Group" := '';
        GenJnlLine."Gen. Prod. Posting Group" := '';
        GenJnlLine."VAT Bus. Posting Group" := '';
        GenJnlLine."VAT Prod. Posting Group" := '';
    end;

    local procedure MarkLinePosted(var ImportLine: Record "BeDyn Cleaning Import Line"; InvoiceNo: Code[20]; PostingDate: Date)
    begin
        ImportLine.Status := ImportLine.Status::Posted;
        ImportLine."Reclass Document No." := InvoiceNo;
        ImportLine."Reclass Posting Date" := PostingDate;
        ImportLine."Error Message" := '';
        ImportLine.Modify(true);
    end;

    // Reabre líneas reclasificadas (p. ej. si el diario preparado se eliminó sin
    // registrar): vuelven a Validada y pierden la referencia al documento.
    procedure ReopenLines(var ImportLineParam: Record "BeDyn Cleaning Import Line")
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
        ReopenedCount: Integer;
        ConfirmQst: Label '¿Reabrir las líneas reclasificadas de la selección? Hazlo solo si el diario generado se eliminó sin registrar; si ya se registró, la reclasificación contable seguirá existiendo.';
        ReopenedMsg: Label '%1 líneas reabiertas.', Comment = '%1 = nº líneas';
    begin
        if not Confirm(ConfirmQst, false) then
            exit;
        ImportLine.Copy(ImportLineParam);
        ImportLine.SetRange(Status, ImportLine.Status::Posted);
        if not ImportLine.FindSet(true) then
            exit;
        repeat
            ImportLine.Status := ImportLine.Status::Validated;
            ImportLine."Reclass Document No." := '';
            ImportLine."Reclass Posting Date" := 0D;
            ImportLine.Modify(true);
            ReopenedCount += 1;
        until ImportLine.Next() = 0;
        Message(ReopenedMsg, ReopenedCount);
    end;

    // ============================ DIARIO ============================

    local procedure GetLastJournalLineNo(): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", PropertySetup."Cleaning Jnl. Template Name");
        GenJnlLine.SetRange("Journal Batch Name", PropertySetup."Cleaning Jnl. Batch Name");
        if GenJnlLine.FindLast() then
            exit(GenJnlLine."Line No.");
        exit(0);
    end;

    local procedure BatchHasOtherLines(): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", PropertySetup."Cleaning Jnl. Template Name");
        GenJnlLine.SetRange("Journal Batch Name", PropertySetup."Cleaning Jnl. Batch Name");
        exit(not GenJnlLine.IsEmpty());
    end;

    local procedure PostBatch()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", PropertySetup."Cleaning Jnl. Template Name");
        GenJnlLine.SetRange("Journal Batch Name", PropertySetup."Cleaning Jnl. Batch Name");
        GenJnlLine.FindFirst();
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJnlLine);
    end;

    // Descripción y unidad del servicio desde el catálogo del proveedor, con el
    // propio código como respaldo si el servicio ya no existe.
    local procedure GetServiceInfo(ImportLine: Record "BeDyn Cleaning Import Line"; var ServiceName: Text; var UnitText: Text)
    var
        CleaningService: Record "BeDyn Cleaning Service";
    begin
        ServiceName := ImportLine."Service Code";
        UnitText := '';
        if not CleaningService.Get(ImportLine."Vendor No.", ImportLine."Service Code") then
            exit;
        if CleaningService.Description <> '' then
            ServiceName := CleaningService.Description;
        UnitText := CleaningService."Unit of Measure Code";
    end;
}
