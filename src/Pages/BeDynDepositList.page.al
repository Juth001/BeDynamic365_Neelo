namespace BeDynamic.PropertyManagement;

page 82533 "BeDyn Deposit List"
{
    PageType = List;
    SourceTable = "BeDyn Deposit";
    Caption = 'Fianzas';
    CardPageId = "BeDyn Deposit Card";
    Editable = false;
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de la fianza.';
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
                field(Months; Rec.Months)
                {
                    ApplicationArea = All;
                    ToolTip = 'Meses de alquiler que cubre la fianza.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Importe de la fianza (sin IVA).';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado de la fianza: pendiente, cobrada, devuelta o retenida.';
                }
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
                field("Retained Amount"; Rec."Retained Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Parte de la fianza retenida en la devolución.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Factura registrada en la que se cobró la fianza.';
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
            }
        }
    }
}
