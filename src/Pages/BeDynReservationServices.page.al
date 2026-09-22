namespace BeDynamic.PropertyManagement;

page 82513 "BeDyn Reservation Services"
{
    PageType = ListPart;
    SourceTable = "BeDyn Reservation Service";
    Caption = 'Servicios adicionales';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Service Code"; Rec."Service Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código del servicio (limpieza, planchado, minibar, etc.).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del servicio.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Cantidad del servicio.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Precio unitario del servicio.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Importe de la línea (cantidad x precio unitario).';
                }
            }
        }
    }
}
