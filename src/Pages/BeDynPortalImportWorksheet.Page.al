namespace BeDynamic.PortalImport;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

page 82601 "BeDyn Portal Import Worksheet"
{
    Caption = 'Importación Portales de Venta';
    PageType = List;
    SourceTable = "BeDyn Portal Import Buffer";
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
                field(Channel; Rec.Channel)
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
                field("Transaction Date"; Rec."Transaction Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Row Type"; Rec."Row Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Reservation Code"; Rec."Reservation Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Guest; Rec.Guest)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Listing; Rec.Listing)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Listing ID"; Rec."Listing ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Nights; Rec.Nights)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Payout Group ID"; Rec."Payout Group ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Reservation Status"; Rec."Reservation Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Reference Code"; Rec."Reference Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Commission Amount"; Rec."Commission Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Payment Fee Amount"; Rec."Payment Fee Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("VAT Fee Amount"; Rec."VAT Fee Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Cleaning Fee"; Rec."Cleaning Fee")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field("Taxes Amount"; Rec."Taxes Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    StyleExpr = StatusStyle;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Paid Out Amount"; Rec."Paid Out Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Property Code"; Rec."Property Code")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
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
                field("Posted Document No."; Rec."Posted Document No.")
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
                Caption = 'Importar CSV...';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Sube el fichero CSV exportado del portal (transacciones de Airbnb o payouts de Booking): el canal se detecta automáticamente por la cabecera. Las líneas se cargan en un lote nuevo y se validan automáticamente.';

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
                ToolTip = 'Vuelve a validar las líneas seleccionadas (pendientes o con error), por ejemplo tras completar el mapeo de alojamientos.';

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Portal Import Buffer";
                    Validation: Codeunit "BeDyn Portal Validation";
                begin
                    BufferSel.Copy(Rec);
                    CurrPage.SetSelectionFilter(BufferSel);
                    Validation.ValidateLines(BufferSel);
                    CurrPage.Update(false);
                end;
            }
            action(ProcessLines)
            {
                Caption = 'Procesar';
                ApplicationArea = All;
                Image = PostBatch;
                ToolTip = 'Contabiliza las líneas validadas de la selección: factura y comisiones de las reservas y traspaso del payout al banco.';

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Portal Import Buffer";
                    Process: Codeunit "BeDyn Portal Import Process";
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
                ToolTip = 'Abre la factura de venta creada o registrada de la reserva seleccionada.';

                trigger OnAction()
                begin
                    OpenDocument();
                end;
            }
            action(ArchivePosted)
            {
                Caption = 'Archivar procesadas';
                ApplicationArea = All;
                Image = Archive;
                ToolTip = 'Mueve al histórico todas las líneas registradas de la vista actual, para dejar la hoja solo con lo pendiente de trabajar.';

                trigger OnAction()
                begin
                    ArchivePostedLines();
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
                RunObject = page "BeDyn Portal Setup";
                ToolTip = 'Abre la configuración de la importación de portales de venta.';
            }
            action(ListingMapping)
            {
                Caption = 'Mapeo alojamientos';
                ApplicationArea = All;
                Image = Dimensions;
                RunObject = page "BeDyn Portal Listing Mapping";
                ToolTip = 'Abre el mapeo de alojamientos de los portales a propiedades.';
            }
            action(OpenArchive)
            {
                Caption = 'Histórico';
                ApplicationArea = All;
                Image = History;
                RunObject = page "BeDyn Portal Import Archive";
                ToolTip = 'Abre el histórico con las líneas archivadas de la hoja de importación.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';
                actionref(ImportCSV_Promoted; ImportCSV) { }
                actionref(ValidateLines_Promoted; ValidateLines) { }
                actionref(ProcessLines_Promoted; ProcessLines) { }
                actionref(ShowDocument_Promoted; ShowDocument) { }
                actionref(ArchivePosted_Promoted; ArchivePosted) { }
            }
            group(Category_Setup)
            {
                Caption = 'Configuración';
                actionref(OpenSetup_Promoted; OpenSetup) { }
                actionref(ListingMapping_Promoted; ListingMapping) { }
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
            Rec.Status in [Rec.Status::Validated, Rec.Status::Posted]:
                StatusStyle := 'Favorable';
            Rec.Status = Rec.Status::Skipped:
                StatusStyle := 'Subordinate';
            else
                StatusStyle := 'Standard';
        end;
    end;

    local procedure ImportFile()
    var
        ListingMappingRec: Record "BeDyn Portal Listing Mapping";
        TempBlob: Codeunit "Temp Blob";
        Reader: Codeunit "BeDyn Portal CSV Reader";
        Validation: Codeunit "BeDyn Portal Validation";
        DetectedChannel: Enum "BeDyn Portal Channel";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
        BatchCode: Code[20];
        ImportedCount: Integer;
        DuplicateCount: Integer;
        MappingCountBefore: Integer;
        UploadTitleLbl: Label 'Selecciona el CSV del portal (Airbnb o Booking)';
        FilterLbl: Label 'Ficheros CSV (*.csv)|*.csv', Locked = true;
        DoneMsg: Label 'Lote %1 (%2): %3 líneas importadas, %4 duplicadas omitidas.', Comment = '%1 = lote, %2 = canal, %3, %4 = contadores';
        NewMappingsMsg: Label 'Se han creado %1 alojamientos nuevos en el mapeo. Revísalos y complétalos, y usa Revalidar antes de procesar, para asegurar que los movimientos se contabilicen correctamente.', Comment = '%1 = contador';
    begin
        if not UploadIntoStream(UploadTitleLbl, '', FilterLbl, FileName, InStr) then
            exit;
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);

        MappingCountBefore := ListingMappingRec.Count();
        BatchCode := CopyStr('PT' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20);
        Reader.ImportFromBlob(TempBlob, BatchCode, DetectedChannel, ImportedCount, DuplicateCount);
        Validation.ValidateBatch(BatchCode);

        Rec.SetRange("Batch Code", BatchCode);
        CurrPage.Update(false);
        Message(DoneMsg, BatchCode, DetectedChannel, ImportedCount, DuplicateCount);
        // Aviso de mapeos auto-creados en la validación: hay que completarlos antes
        // de procesar (mismo patrón en todas las hojas de importación).
        if ListingMappingRec.Count() > MappingCountBefore then
            Message(NewMappingsMsg, ListingMappingRec.Count() - MappingCountBefore);
    end;

    // Mueve las líneas registradas de la vista actual (respetando los filtros
    // activos, p.ej. el lote) a la tabla de histórico y las borra de la hoja.
    local procedure ArchivePostedLines()
    var
        BufferPosted: Record "BeDyn Portal Import Buffer";
        ArchiveLine: Record "BeDyn Portal Import Archive";
        ArchivedCount: Integer;
        ConfirmQst: Label '¿Quieres archivar %1 líneas registradas? Se moverán al histórico y desaparecerán de esta hoja.', Comment = '%1 = contador de líneas';
        NothingMsg: Label 'No hay líneas registradas que archivar en la vista actual.';
        DoneMsg: Label '%1 líneas movidas al histórico.', Comment = '%1 = contador de líneas';
    begin
        BufferPosted.Copy(Rec);
        BufferPosted.SetRange(Status, BufferPosted.Status::Posted);
        if BufferPosted.IsEmpty() then begin
            Message(NothingMsg);
            exit;
        end;
        if not Confirm(ConfirmQst, true, BufferPosted.Count()) then
            exit;
        BufferPosted.FindSet();
        repeat
            ArchiveLine.Init();
            ArchiveLine.TransferFields(BufferPosted);
            ArchiveLine."Archived Date" := CurrentDateTime();
            ArchiveLine."Archived By" := CopyStr(UserId(), 1, MaxStrLen(ArchiveLine."Archived By"));
            ArchiveLine.Insert(true);
            ArchivedCount += 1;
        until BufferPosted.Next() = 0;
        BufferPosted.DeleteAll(true);
        CurrPage.Update(false);
        Message(DoneMsg, ArchivedCount);
    end;

    // Mismo patrón que la hoja de Pleo: abre el documento de la línea, el
    // registrado si existe y si no el borrador.
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
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if Rec."Posted Document No." = '' then
            exit(false);
        if SalesInvHeader.Get(Rec."Posted Document No.") then begin
            Page.Run(Page::"Posted Sales Invoice", SalesInvHeader);
            exit(true);
        end;
        // Los ajustes de resolución se registran como abono.
        if SalesCrMemoHeader.Get(Rec."Posted Document No.") then begin
            Page.Run(Page::"Posted Sales Credit Memo", SalesCrMemoHeader);
            exit(true);
        end;
        exit(false);
    end;

    local procedure OpenCreatedDocument(): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec."Created Invoice No." = '' then
            exit(false);
        if SalesHeader.Get(SalesHeader."Document Type"::Invoice, Rec."Created Invoice No.") then begin
            Page.Run(Page::"Sales Invoice", SalesHeader);
            exit(true);
        end;
        if SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", Rec."Created Invoice No.") then begin
            Page.Run(Page::"Sales Credit Memo", SalesHeader);
            exit(true);
        end;
        exit(false);
    end;
}
