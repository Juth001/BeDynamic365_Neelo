namespace BeDynamic.CleaningImport;

page 82700 "BeDyn Cleaning Import Wksh."
{
    PageType = List;
    SourceTable = "BeDyn Cleaning Import Line";
    SourceTableView = sorting("Entry No.") order(descending);
    Caption = 'Hoja importación limpiezas';
    UsageCategory = Tasks;
    ApplicationArea = All;
    InsertAllowed = false;
    AnalysisModeEnabled = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Batch Code"; Rec."Batch Code")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                    Visible = false;
                }
                field("Row No."; Rec."Row No.")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Service Date"; Rec."Service Date")
                {
                    Editable = true;
                    StyleExpr = StatusStyle;
                }
                field("Property Code"; Rec."Property Code")
                {
                    StyleExpr = StatusStyle;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    StyleExpr = StatusStyle;
                }
                field("Service Code"; Rec."Service Code")
                {
                    StyleExpr = StatusStyle;
                }
                field("Service Description"; Rec."Service Description")
                {
                    StyleExpr = StatusStyle;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    StyleExpr = StatusStyle;
                }
                field(Amount; Rec.Amount)
                {
                    StyleExpr = StatusStyle;
                }
                field("Expected Unit Price"; Rec."Expected Unit Price")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Allow Deviation"; Rec."Allow Deviation")
                {
                    StyleExpr = StatusStyle;
                }
                field("Job No."; Rec."Job No.")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                    Visible = false;
                }
                field("Invoice No."; Rec."Invoice No.")
                {
                    StyleExpr = StatusStyle;
                }
                field("Error Message"; Rec."Error Message")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Warning Message"; Rec."Warning Message")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Reclass Document No."; Rec."Reclass Document No.")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Reclass Posting Date"; Rec."Reclass Posting Date")
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
                    Visible = false;
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
                ApplicationArea = All;
                Caption = 'Importar CSV';
                Image = Import;
                ToolTip = 'Importa el fichero mensual del proveedor de limpieza. Cada fila genera hasta tres líneas (limpieza, lavandería y amenities) con sus costes sin IVA.';

                trigger OnAction()
                var
                    CSVImport: Codeunit "BeDyn Cleaning CSV Import";
                    BatchCode: Code[20];
                begin
                    BatchCode := CSVImport.ImportCSV();
                    if BatchCode <> '' then begin
                        Rec.SetRange("Batch Code", BatchCode);
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(ValidateLines)
            {
                ApplicationArea = All;
                Caption = 'Validar';
                Image = CheckRulesSyntax;
                ToolTip = 'Valida las líneas seleccionadas pendientes o con error: resuelve proyecto, tarea y cuenta, y comprueba el importe contra el precio pactado.';

                trigger OnAction()
                var
                    ImportLine: Record "BeDyn Cleaning Import Line";
                    Validation: Codeunit "BeDyn Cleaning Validation";
                begin
                    CurrPage.SetSelectionFilter(ImportLine);
                    Validation.ValidateLines(ImportLine);
                    CurrPage.Update(false);
                end;
            }
            action(AssignInvoice)
            {
                ApplicationArea = All;
                Caption = 'Asignar factura...';
                Image = ApplyEntries;
                ToolTip = 'Asigna una factura registrada del proveedor de limpieza a las líneas seleccionadas.';

                trigger OnAction()
                var
                    ImportLine: Record "BeDyn Cleaning Import Line";
                    ReclassMgt: Codeunit "BeDyn Cleaning Reclass Mgt.";
                begin
                    CurrPage.SetSelectionFilter(ImportLine);
                    ReclassMgt.AssignInvoice(ImportLine);
                    CurrPage.Update(false);
                end;
            }
            action(ShowMatch)
            {
                ApplicationArea = All;
                Caption = 'Comprobar cuadre';
                Image = Balance;
                ToolTip = 'Compara, para las facturas de la selección, la base imponible con la suma de las líneas asignadas.';

                trigger OnAction()
                var
                    ImportLine: Record "BeDyn Cleaning Import Line";
                    ReclassMgt: Codeunit "BeDyn Cleaning Reclass Mgt.";
                begin
                    CurrPage.SetSelectionFilter(ImportLine);
                    ReclassMgt.ShowMatchStatus(ImportLine);
                end;
            }
            action(GenerateReclass)
            {
                ApplicationArea = All;
                Caption = 'Generar reclasificación';
                Image = TransferToGeneralJournal;
                ToolTip = 'Genera el diario de reclasificación de las facturas de la selección: abona la cuenta puente y carga las cuentas de gasto con proyecto, tarea y cantidad. Cada factura debe cuadrar con sus líneas antes de generarse.';

                trigger OnAction()
                var
                    ImportLine: Record "BeDyn Cleaning Import Line";
                    ReclassMgt: Codeunit "BeDyn Cleaning Reclass Mgt.";
                begin
                    CurrPage.SetSelectionFilter(ImportLine);
                    ReclassMgt.GenerateReclass(ImportLine);
                    CurrPage.Update(false);
                end;
            }
            action(ReopenLines)
            {
                ApplicationArea = All;
                Caption = 'Reabrir';
                Image = ReOpen;
                ToolTip = 'Devuelve a Validada las líneas reclasificadas de la selección. Úsalo solo si el diario generado se eliminó sin registrar.';

                trigger OnAction()
                var
                    ImportLine: Record "BeDyn Cleaning Import Line";
                    ReclassMgt: Codeunit "BeDyn Cleaning Reclass Mgt.";
                begin
                    CurrPage.SetSelectionFilter(ImportLine);
                    ReclassMgt.ReopenLines(ImportLine);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(PendingInvoices)
            {
                ApplicationArea = All;
                Caption = 'Facturas pendientes';
                Image = PurchaseInvoice;
                RunObject = page "BeDyn Cleaning Pending Inv.";
                ToolTip = 'Facturas registradas del proveedor de limpieza con su importe asignado, reclasificado y pendiente de distribuir.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ImportCSV_Promoted; ImportCSV)
                {
                }
                actionref(ValidateLines_Promoted; ValidateLines)
                {
                }
                actionref(AssignInvoice_Promoted; AssignInvoice)
                {
                }
                actionref(ShowMatch_Promoted; ShowMatch)
                {
                }
                actionref(GenerateReclass_Promoted; GenerateReclass)
                {
                }
            }
        }
    }

    views
    {
        view(PendingLines)
        {
            Caption = 'Pendientes';
            Filters = where(Status = const(Pending));
        }
        view(ErrorLines)
        {
            Caption = 'Con error';
            Filters = where(Status = const(Error));
        }
        view(ValidatedLines)
        {
            Caption = 'Validadas';
            Filters = where(Status = const(Validated));
        }
        view(PostedLines)
        {
            Caption = 'Reclasificadas';
            Filters = where(Status = const(Posted));
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case true of
            Rec.Status = Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status = Rec.Status::Posted:
                StatusStyle := 'Favorable';
            Rec."Warning Message" <> '':
                StatusStyle := 'Ambiguous';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
