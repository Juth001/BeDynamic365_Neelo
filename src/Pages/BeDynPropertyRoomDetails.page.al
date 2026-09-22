namespace BeDynamic.PropertyManagement;

page 82531 "BeDyn Property Room Details"
{
    PageType = CardPart;
    SourceTable = "BeDyn Property Room";
    Caption = 'Detalles subpropiedad';
    Editable = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            field("Room No."; Rec."Room No.")
            {
                ApplicationArea = All;
                ToolTip = 'Número o código de la subpropiedad.';
            }
            field("No. of Reservations"; Rec."No. of Reservations")
            {
                ApplicationArea = All;
                ToolTip = 'Número de reservas de esta subpropiedad. Haga clic para ver las reservas.';
                DrillDownPageId = "BeDyn Reservation List";
            }
        }
    }
}
