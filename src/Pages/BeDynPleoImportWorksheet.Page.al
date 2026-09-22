namespace BeDynamic.PleoImport;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Utilities;

page 82101 "BeDyn Pleo Import Worksheet"
{
    Caption = 'Importación Gastos Pleo';
    PageType = List;
    SourceTable = "BeDyn Pleo Import Buffer";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = Tasks;
    ApplicationArea = All;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Batch Code"; Rec."Batch Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Expense Date"; Rec."Expense Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Receipt No."; Rec."Receipt No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Expense Type"; Rec."Expense Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Source Description"; Rec."Source Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Owner; Rec.Owner)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Note; Rec.Note)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field(Team; Rec.Team)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Receipt URL"; Rec."Receipt URL")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Project Code"; Rec."Project Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Category; Rec.Category)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Pleo Vendor Code"; Rec."Pleo Vendor Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Pleo Vendor Name"; Rec."Pleo Vendor Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Mapped Vendor No."; Rec."Mapped Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Proveedor BC con el que se creará la factura. Se puede corregir a mano antes de procesar.';
                    StyleExpr = StatusStyle;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Comprador que se asigna a la factura (resuelto del empleado de Pleo). Se puede corregir a mano antes de procesar.';
                    StyleExpr = StatusStyle;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta de gasto de la línea. Se puede corregir a mano antes de procesar.';
                    StyleExpr = StatusStyle;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field(CAPEX; Rec.CAPEX)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Extraordinary; Rec.Extraordinary)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Fixed Asset No."; Rec."Fixed Asset No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Warning Message"; Rec."Warning Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Created Document No."; Rec."Created Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Payment Posted"; Rec."Payment Posted")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportCSV)
            {
                Caption = 'Importar CSV de Pleo...';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Sube el fichero CSV exportado de Pleo. Las líneas se cargan en un lote nuevo y se validan automáticamente.';

                trigger OnAction()
                begin
                    ImportFile();
                end;
            }
            action(ValidateLines)
            {
                Caption = 'Revalidar';
                ApplicationArea = All;
                Image = CheckRulesSyntax;
                ToolTip = 'Vuelve a validar las líneas seleccionadas (pendientes o con error), por ejemplo tras completar los mapeos.';

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Pleo Import Buffer";
                    Validation: Codeunit "BeDyn Pleo Validation";
                begin
                    BufferSel.Copy(Rec);
                    CurrPage.SetSelectionFilter(BufferSel);
                    Validation.ValidateLines(BufferSel);
                    CurrPage.Update(false);
                end;
            }
            action(PreviewPosting)
            {
                Caption = 'Vista previa del registro';
                ApplicationArea = All;
                Image = ViewDetails;
                ToolTip = 'Muestra, sin registrar nada, los documentos y diarios que se generarán al procesar las líneas validadas de la selección.';

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Pleo Import Buffer";
                    TempPreview: Record "BeDyn Pleo Posting Preview" temporary;
                    Process: Codeunit "BeDyn Pleo Import Process";
                    NothingMsg: Label 'No hay líneas validadas en la selección.';
                begin
                    BufferSel.Copy(Rec);
                    CurrPage.SetSelectionFilter(BufferSel);
                    Process.BuildPreview(BufferSel, TempPreview);
                    if TempPreview.IsEmpty() then begin
                        Message(NothingMsg);
                        exit;
                    end;
                    Page.RunModal(Page::"BeDyn Pleo Posting Preview", TempPreview);
                end;
            }
            action(ProcessLines)
            {
                Caption = 'Procesar';
                ApplicationArea = All;
                Image = PostBatch;
                ToolTip = 'Crea las facturas/abonos de compra de las líneas validadas y, según la configuración, las registra y genera el pago contra el banco Pleo.';

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Pleo Import Buffer";
                    Process: Codeunit "BeDyn Pleo Import Process";
                begin
                    BufferSel.Copy(Rec);
                    CurrPage.SetSelectionFilter(BufferSel);
                    Process.ProcessLines(BufferSel);
                    CurrPage.Update(false);
                end;
            }
            action(ShowDocument)
            {
                Caption = 'Ver documento';
                ApplicationArea = All;
                Image = Document;
                ToolTip = 'Abre el documento de compra creado o registrado de la línea seleccionada.';

                trigger OnAction()
                begin
                    OpenDocument();
                end;
            }
            action(ArchiveProcessed)
            {
                Caption = 'Archivar procesadas';
                ApplicationArea = All;
                Image = Archive;
                ToolTip = 'Mueve al Archivo Gastos Pleo las líneas de la selección ya procesadas (documento creado, registradas o pagadas). El procesado normal las archiva solo; esta acción es para líneas antiguas o filtradas.';

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Pleo Import Buffer";
                    Process: Codeunit "BeDyn Pleo Import Process";
                    ArchivedCount: Integer;
                    ConfirmQst: Label 'Se moverán al archivo las líneas procesadas (documento creado, registradas o pagadas) de la selección y desaparecerán de esta hoja. ¿Continuar?';
                    ArchivedMsg: Label '%1 líneas movidas al archivo.', Comment = '%1 = contador';
                begin
                    if not Confirm(ConfirmQst) then
                        exit;
                    BufferSel.Copy(Rec);
                    CurrPage.SetSelectionFilter(BufferSel);
                    ArchivedCount := Process.ArchiveProcessedLines(BufferSel);
                    CurrPage.Update(false);
                    Message(ArchivedMsg, ArchivedCount);
                end;
            }
            action(ArchiveSkipped)
            {
                Caption = 'Archivar omitidas';
                ApplicationArea = All;
                Image = Archive;
                ToolTip = 'Mueve al Archivo Gastos Pleo las líneas omitidas de la selección (importe cero, recargas o cashback desactivados...) y las quita de esta hoja. Su Id. de gasto Pleo se sigue teniendo en cuenta para no reimportarlas.';

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Pleo Import Buffer";
                    Process: Codeunit "BeDyn Pleo Import Process";
                    ArchivedCount: Integer;
                    ConfirmQst: Label 'Se moverán al archivo las líneas omitidas de la selección y desaparecerán de esta hoja. ¿Continuar?';
                    ArchivedMsg: Label '%1 líneas movidas al archivo.', Comment = '%1 = contador';
                begin
                    if not Confirm(ConfirmQst) then
                        exit;
                    BufferSel.Copy(Rec);
                    CurrPage.SetSelectionFilter(BufferSel);
                    ArchivedCount := Process.ArchiveSkippedLines(BufferSel);
                    CurrPage.Update(false);
                    Message(ArchivedMsg, ArchivedCount);
                end;
            }
            action(ShowAllBatches)
            {
                Caption = 'Ver todos los lotes';
                ApplicationArea = All;
                Image = ClearFilter;
                ToolTip = 'Quita el filtro de lote y muestra todas las líneas importadas.';

                trigger OnAction()
                begin
                    Rec.SetRange("Batch Code");
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(OpenSetup)
            {
                Caption = 'Configuración';
                ApplicationArea = All;
                Image = Setup;
                RunObject = page "BeDyn Pleo Setup";
                ToolTip = 'Abre la configuración de la importación de Pleo.';
            }
            action(VendorMapping)
            {
                Caption = 'Mapeo proveedores';
                ApplicationArea = All;
                Image = VendorLedger;
                RunObject = page "BeDyn Pleo Vendor Mapping";
                ToolTip = 'Abre el mapeo de códigos de proveedor de Pleo a proveedores BC.';
            }
            action(ExpenseMap)
            {
                Caption = 'Mapeo categorías';
                ApplicationArea = All;
                Image = ChartOfAccounts;
                RunObject = page "BeDyn Pleo Expense Type Map";
                ToolTip = 'Abre el mapeo de categorías de Pleo a cuentas contables, tratamiento CAPEX y tareas de proyecto.';
            }
            action(PurchaserMapping)
            {
                Caption = 'Mapeo compradores';
                ApplicationArea = All;
                Image = SalesPerson;
                RunObject = page "BeDyn Pleo Purchaser Mapping";
                ToolTip = 'Abre el mapeo de empleados de Pleo a compradores/vendedores BC.';
            }
            action(OpenArchive)
            {
                Caption = 'Archivo de gastos';
                ApplicationArea = All;
                Image = History;
                RunObject = page "BeDyn Pleo Expense Archive";
                ToolTip = 'Abre el histórico de gastos Pleo ya procesados y archivados.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';
                actionref(ImportCSV_Promoted; ImportCSV) { }
                actionref(ValidateLines_Promoted; ValidateLines) { }
                actionref(PreviewPosting_Promoted; PreviewPosting) { }
                actionref(ProcessLines_Promoted; ProcessLines) { }
                actionref(ShowDocument_Promoted; ShowDocument) { }
            }
            group(Category_Setup)
            {
                Caption = 'Configuración';
                actionref(OpenSetup_Promoted; OpenSetup) { }
                actionref(VendorMapping_Promoted; VendorMapping) { }
                actionref(ExpenseMap_Promoted; ExpenseMap) { }
                actionref(PurchaserMapping_Promoted; PurchaserMapping) { }
                actionref(OpenArchive_Promoted; OpenArchive) { }
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        // Prioridad: error (rojo) > aviso (amarillo) > OK (verde) > omitida (gris).
        case true of
            Rec.Status = Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec."Warning Message" <> '':
                StatusStyle := 'Ambiguous';
            Rec.Status in [Rec.Status::Validated, Rec.Status::Created, Rec.Status::Posted, Rec.Status::Paid]:
                StatusStyle := 'Favorable';
            Rec.Status = Rec.Status::Skipped:
                StatusStyle := 'Subordinate';
            else
                StatusStyle := 'Standard';
        end;
    end;

    local procedure ImportFile()
    var
        VendorMapping: Record "BeDyn Pleo Vendor Mapping";
        PurchaserMapping: Record "BeDyn Pleo Purchaser Mapping";
        ExpenseTypeMap: Record "BeDyn Pleo Expense Type Map";
        TempBlob: Codeunit "Temp Blob";
        Reader: Codeunit "BeDyn Pleo CSV Reader";
        Validation: Codeunit "BeDyn Pleo Validation";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
        BatchCode: Code[20];
        ImportedCount: Integer;
        DuplicateCount: Integer;
        MappingCountBefore: Integer;
        NewMappingCount: Integer;
        UploadTitleLbl: Label 'Selecciona el CSV exportado de Pleo';
        FilterLbl: Label 'Ficheros CSV (*.csv)|*.csv', Locked = true;
        DoneMsg: Label 'Lote %1: %2 líneas importadas, %3 duplicadas omitidas.', Comment = '%1 = lote, %2, %3 = contadores';
        NewMappingsMsg: Label 'Se han creado %1 mapeos nuevos (proveedores, compradores o categorías). Revísalos y complétalos, y usa Revalidar antes de procesar, para asegurar que los movimientos se contabilicen correctamente.', Comment = '%1 = contador';
    begin
        if not UploadIntoStream(UploadTitleLbl, '', FilterLbl, FileName, InStr) then
            exit;
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);

        MappingCountBefore := VendorMapping.Count() + PurchaserMapping.Count() + ExpenseTypeMap.Count();
        BatchCode := CopyStr('PL' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20);
        Reader.ImportFromBlob(TempBlob, BatchCode, ImportedCount, DuplicateCount);
        Validation.ValidateBatch(BatchCode);

        Rec.SetRange("Batch Code", BatchCode);
        CurrPage.Update(false);
        Message(DoneMsg, BatchCode, ImportedCount, DuplicateCount);
        // Aviso de mapeos auto-creados en la validación: hay que completarlos antes
        // de procesar (mismo patrón en todas las hojas de importación).
        NewMappingCount := VendorMapping.Count() + PurchaserMapping.Count() + ExpenseTypeMap.Count() - MappingCountBefore;
        if NewMappingCount > 0 then
            Message(NewMappingsMsg, NewMappingCount);
    end;

    local procedure OpenDocument()
    var
        NoDocMsg: Label 'La línea no tiene ningún documento asociado.';
    begin
        if OpenPostedDocument() then
            exit;
        if OpenCreatedDocument() then
            exit;
        Message(NoDocMsg);
    end;

    local procedure OpenPostedDocument(): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        if Rec."Posted Document No." = '' then
            exit(false);
        if Rec.Amount < 0 then begin
            if not PurchInvHeader.Get(Rec."Posted Document No.") then
                exit(false);
            Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
            exit(true);
        end;
        if not PurchCrMemoHdr.Get(Rec."Posted Document No.") then
            exit(false);
        Page.Run(Page::"Posted Purchase Credit Memo", PurchCrMemoHdr);
        exit(true);
    end;

    local procedure OpenCreatedDocument(): Boolean
    var
        PurchHeader: Record "Purchase Header";
    begin
        if Rec."Created Document No." = '' then
            exit(false);
        if Rec.Amount < 0 then begin
            if not PurchHeader.Get(PurchHeader."Document Type"::Invoice, Rec."Created Document No.") then
                exit(false);
            Page.Run(Page::"Purchase Invoice", PurchHeader);
            exit(true);
        end;
        if not PurchHeader.Get(PurchHeader."Document Type"::"Credit Memo", Rec."Created Document No.") then
            exit(false);
        Page.Run(Page::"Purchase Credit Memo", PurchHeader);
        exit(true);
    end;
}
