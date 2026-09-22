namespace BeDynamic.PropertyManagement;

page 82534 "BeDyn Deposit Card"
{
    PageType = Card;
    SourceTable = "BeDyn Deposit";
    Caption = 'Fianza';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de la fianza.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Reservation No."; Rec."Reservation No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Reserva a la que corresponde la fianza.';
                }
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad de la reserva.';
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Subpropiedad de la reserva.';
                }
                field("Tenant No."; Rec."Tenant No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Inquilino que paga la fianza.';
                }
                field("Tenant Name"; Rec."Tenant Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del inquilino.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado de la fianza. Se cambia con las acciones Registrar cobro y Registrar devolución, o al registrar la factura que la incluye.';
                }
            }
            group(Amounts)
            {
                Caption = 'Importes';

                field(Months; Rec.Months)
                {
                    ApplicationArea = All;
                    ToolTip = 'Meses de alquiler que cubre la fianza. Se toma de la propiedad al confirmar la reserva.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Importe de la fianza (sin IVA). Editable mientras está pendiente.';
                }
                field("Returned Amount"; Rec."Returned Amount")
                {
                    ApplicationArea = All;
                }
                field("Retained Amount"; Rec."Retained Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Parte de la fianza que se retiene en la devolución (desperfectos, impagos, etc.). Introdúzcalo antes de registrar la devolución.';
                }
            }
            group(Dates)
            {
                Caption = 'Fechas';

                field("Collection Date"; Rec."Collection Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha en que se cobró la fianza.';
                }
                field("Return Date"; Rec."Return Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha en que se devolvió la fianza.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Factura registrada en la que se cobró la fianza.';
                }
            }
            group(Accounting)
            {
                Caption = 'Contabilidad';

                field("Posting Document No."; Rec."Posting Document No.")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
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
            action(MarkCollected)
            {
                ApplicationArea = All;
                Caption = 'Registrar cobro';
                Image = Payment;
                ToolTip = 'Marca la fianza como cobrada con la fecha de trabajo. Úselo cuando la fianza se cobra aparte, sin factura.';

                trigger OnAction()
                begin
                    Rec.MarkCollected();
                    CurrPage.Update(false);
                end;
            }
            action(MarkReturned)
            {
                ApplicationArea = All;
                Caption = 'Registrar devolución';
                Image = Undo;
                ToolTip = 'Marca la fianza como devuelta. Si tiene importe retenido, queda como retenida.';

                trigger OnAction()
                begin
                    Rec.MarkReturned();
                    CurrPage.Update(false);
                end;
            }
            action(PostDeposit)
            {
                ApplicationArea = All;
                Caption = 'Registrar asiento';
                Image = PostOrder;
                Enabled = DepositNotPosted;
                ToolTip = 'Carga la cuenta puente y abona la cuenta de fianzas por el importe de la fianza, con el nº de la reserva como documento.';

                trigger OnAction()
                var
                    DepositPosting: Codeunit "BeDyn Deposit Posting";
                begin
                    DepositPosting.PostDeposit(Rec, 0D);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(LedgerEntries)
            {
                ApplicationArea = All;
                Caption = 'Movimientos contables';
                Image = GLRegisters;
                Enabled = DepositPosted;
                ToolTip = 'Movimientos contables del asiento de la fianza: el cargo en la cuenta puente y el abono en la cuenta de fianzas.';

                trigger OnAction()
                begin
                    Rec.ShowLedgerEntries();
                end;
            }
            action(NavigateDocument)
            {
                ApplicationArea = All;
                Caption = 'Navegar';
                Image = Navigate;
                Enabled = DepositPosted;
                ToolTip = 'Busca todos los documentos y movimientos registrados con el documento de esta fianza.';

                trigger OnAction()
                begin
                    Rec.NavigateDocument();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(MarkCollected_Promoted; MarkCollected)
                {
                }
                actionref(MarkReturned_Promoted; MarkReturned)
                {
                }
                actionref(PostDeposit_Promoted; PostDeposit)
                {
                }
                actionref(LedgerEntries_Promoted; LedgerEntries)
                {
                }
            }
        }
    }

    var
        DepositPosted: Boolean;
        DepositNotPosted: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        DepositPosted := Rec.IsPosted();
        DepositNotPosted := not DepositPosted;
    end;
}
