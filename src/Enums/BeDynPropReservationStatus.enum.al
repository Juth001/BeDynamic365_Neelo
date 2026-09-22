namespace BeDynamic.PropertyManagement;

enum 82502 "BeDyn Prop. Reservation Status"
{
    Extensible = true;
    Caption = 'Estado de reserva';

    value(0; Pending)
    {
        Caption = 'Pendiente';
    }
    value(1; Confirmed)
    {
        Caption = 'Confirmada';
    }
    value(2; CheckedIn)
    {
        Caption = 'Check-In';
    }
    value(3; CheckedOut)
    {
        Caption = 'Check-Out';
    }
    value(4; Cancelled)
    {
        Caption = 'Cancelada';
    }
}
