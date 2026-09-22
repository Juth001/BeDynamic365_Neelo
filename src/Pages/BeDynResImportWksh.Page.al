namespace BeDynamic.ReservationImport;

page 82800 "BeDyn Res. Import Wksh."
{
    // Hoja de trabajo de la importación de reservas y fianzas: se importa el
    // fichero, se valida, se revisan errores y avisos, y solo entonces se procesa.

    PageType = Worksheet;
    SourceTable = "BeDyn Res. Import Line";
    Caption = 'Hoja importación reservas';
    UsageCategory = Tasks;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = true;
    SourceTableView = sorting("Batch Code", "Row No.");

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                ShowCaption = false;

                field(BatchFilterCtrl; BatchFilter)
                {
                    Caption = 'Lote';
                    ApplicationArea = All;
                    ToolTip = 'Lote de importación que se está revisando. Cada fichero importado genera el suyo.';

                    trigger OnValidate()
                    begin
                        ApplyBatchFilter();
                    end;
                }
            }
            repeater(Lines)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Estado de la línea tras validar. Solo se procesan las validadas y las que solo tienen avisos.';
                }
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de fila del fichero, para localizarla en el original.';
                }
                field("External Code"; Rec."External Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código de reserva del origen. Puede venir vacío en las reservas gestionadas a mano.';
                }
                field("Guest Name"; Rec."Guest Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del huésped tal y como viene en el fichero.';
                }
                field("Tenant No."; Rec."Tenant No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Inquilino con el que se ha casado el nombre del fichero.';
                }
                field("New Tenant"; Rec."New Tenant")
                {
                    ApplicationArea = All;
                }
                field("Mgt. Company Code"; Rec."Mgt. Company Code")
                {
                    ApplicationArea = All;
                }
                field("Target Company"; Rec."Target Company")
                {
                    ApplicationArea = All;
                }
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad resuelta a partir del Id interno del fichero.';
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Subpropiedad resuelta. En blanco significa reserva de la propiedad completa.';
                }
                field("Check-In Date"; Rec."Check-In Date")
                {
                    ApplicationArea = All;
                }
                field("Check-Out Date"; Rec."Check-Out Date")
                {
                    ApplicationArea = All;
                }
                field("Nights CSV"; Rec."Nights CSV")
                {
                    ApplicationArea = All;
                }
                field("Channel CSV"; Rec."Channel CSV")
                {
                    ApplicationArea = All;
                }
                field("Deposit Amount"; Rec."Deposit Amount")
                {
                    ApplicationArea = All;
                }
                field("Returned Amount"; Rec."Returned Amount")
                {
                    ApplicationArea = All;
                }
                field("Retained Amount"; Rec."Retained Amount")
                {
                    ApplicationArea = All;
                }
                field("Balance Amount"; Rec."Balance Amount")
                {
                    ApplicationArea = All;
                }
                field("Contract Amount"; Rec."Contract Amount")
                {
                    ApplicationArea = All;
                }
                field("Monthly Rent"; Rec."Monthly Rent")
                {
                    ApplicationArea = All;
                }
                field("Existing Reservation"; Rec."Existing Reservation")
                {
                    ApplicationArea = All;
                }
                field("Reservation No."; Rec."Reservation No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Reserva creada o encontrada para esta línea.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    ToolTip = 'Motivo por el que la línea no se puede procesar.';
                }
                field("Warning Message"; Rec."Warning Message")
                {
                    ApplicationArea = All;
                    Style = Ambiguous;
                    ToolTip = 'Diferencias entre el fichero y lo calculado que no impiden importar la reserva.';
                }
                field(Remark; Rec.Remark)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportFile)
            {
                ApplicationArea = All;
                Caption = 'Importar fichero';
                Image = Import;
                ToolTip = 'Carga un fichero CSV de reservas y fianzas en un lote nuevo y lo valida.';

                trigger OnAction()
                var
                    CSVReader: Codeunit "BeDyn Res. CSV Reader";
                    Router: Codeunit "BeDyn Res. Import Router";
                    Validation: Codeunit "BeDyn Res. Import Validation";
                    NewBatch: Code[20];
                begin
                    NewBatch := CSVReader.ImportCSV();
                    if NewBatch = '' then
                        exit;
                    // Primero se reparten por empresa: validar antes no tendría
                    // sentido, porque las propiedades de otras empresas no están
                    // en esta y saldrían todas en error.
                    Router.DistributeBatch(NewBatch);
                    Validation.ValidateBatch(NewBatch);
                    BatchFilter := NewBatch;
                    ApplyBatchFilter();
                    CurrPage.Update(false);
                end;
            }
            action(DistributeByCompany)
            {
                ApplicationArea = All;
                Caption = 'Distribuir por empresa';
                Image = ChangeTo;
                ToolTip = 'Reparte las líneas según la empresa gestora del código de propiedad: las de otras empresas se envían a la hoja de importación de la suya.';

                trigger OnAction()
                var
                    Router: Codeunit "BeDyn Res. Import Router";
                begin
                    TestBatchSelected();
                    Router.DistributeBatch(BatchFilter);
                    CurrPage.Update(false);
                end;
            }
            action(ValidateLines)
            {
                ApplicationArea = All;
                Caption = 'Validar';
                Image = Approve;
                ToolTip = 'Vuelve a resolver las líneas del lote contra los maestros y actualiza errores y avisos.';

                trigger OnAction()
                var
                    Validation: Codeunit "BeDyn Res. Import Validation";
                begin
                    TestBatchSelected();
                    Validation.ValidateBatch(BatchFilter);
                    CurrPage.Update(false);
                end;
            }
            action(ProcessLines)
            {
                ApplicationArea = All;
                Caption = 'Procesar';
                Image = PostDocument;
                ToolTip = 'Crea los inquilinos, las reservas y las fianzas de las líneas validadas. Las que tienen error se quedan fuera.';

                trigger OnAction()
                var
                    ImportProcess: Codeunit "BeDyn Res. Import Process";
                begin
                    TestBatchSelected();
                    ImportProcess.ProcessBatch(BatchFilter);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteBatch)
            {
                ApplicationArea = All;
                Caption = 'Eliminar lote';
                Image = Delete;
                ToolTip = 'Borra las líneas del lote de la hoja. No deshace lo que ya se haya procesado.';

                trigger OnAction()
                var
                    ImportLine: Record "BeDyn Res. Import Line";
                    DeleteQst: Label '¿Eliminar las líneas del lote %1 de la hoja de importación?', Comment = '%1 = lote';
                begin
                    TestBatchSelected();
                    if not Confirm(DeleteQst, false, BatchFilter) then
                        exit;
                    ImportLine.SetRange("Batch Code", BatchFilter);
                    ImportLine.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ImportFile_Promoted; ImportFile)
                {
                }
                actionref(DistributeByCompany_Promoted; DistributeByCompany)
                {
                }
                actionref(ValidateLines_Promoted; ValidateLines)
                {
                }
                actionref(ProcessLines_Promoted; ProcessLines)
                {
                }
            }
        }
    }

    var
        BatchFilter: Code[20];
        StatusStyle: Text;
        NoBatchErr: Label 'Selecciona primero un lote de importación.';

    trigger OnAfterGetRecord()
    begin
        StatusStyle := StatusStyleExpr();
    end;

    trigger OnOpenPage()
    var
        ImportLine: Record "BeDyn Res. Import Line";
    begin
        // Al abrir se propone el último lote importado, que es sobre el que se
        // trabaja el 99% de las veces.
        if BatchFilter = '' then begin
            ImportLine.SetCurrentKey("Entry No.");
            if ImportLine.FindLast() then
                BatchFilter := ImportLine."Batch Code";
        end;
        ApplyBatchFilter();
    end;

    local procedure ApplyBatchFilter()
    begin
        if BatchFilter = '' then
            Rec.SetRange("Batch Code")
        else
            Rec.SetRange("Batch Code", BatchFilter);
        CurrPage.Update(false);
    end;

    local procedure TestBatchSelected()
    begin
        if BatchFilter = '' then
            Error(NoBatchErr);
    end;

    local procedure StatusStyleExpr(): Text
    var
        UnfavorableTok: Label 'Unfavorable', Locked = true;
        AmbiguousTok: Label 'Ambiguous', Locked = true;
        FavorableTok: Label 'Favorable', Locked = true;
        StandardTok: Label 'Standard', Locked = true;
    begin
        case Rec.Status of
            Rec.Status::Error:
                exit(UnfavorableTok);
            Rec.Status::Warning:
                exit(AmbiguousTok);
            Rec.Status::Processed:
                exit(FavorableTok);
            else
                exit(StandardTok);
        end;
    end;
}
