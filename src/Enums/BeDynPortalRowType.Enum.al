namespace BeDynamic.PortalImport;

enum 82601 "BeDyn Portal Row Type"
{
    Extensible = true;
    Caption = 'Tipo movimiento portal';

    value(0; Reservation)
    {
        Caption = 'Reserva';
    }
    value(1; Payout)
    {
        Caption = 'Payout';
    }
    value(2; Adjustment)
    {
        Caption = 'Ajuste de resolución';
    }
    value(9; Other)
    {
        Caption = 'Otro';
    }
}
