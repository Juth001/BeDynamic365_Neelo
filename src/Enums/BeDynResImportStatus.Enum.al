namespace BeDynamic.ReservationImport;

enum 82800 "BeDyn Res. Import Status"
{
    Extensible = true;
    Caption = 'Estado de línea';

    value(0; Pending)
    {
        Caption = 'Pendiente';
    }
    value(1; Validated)
    {
        Caption = 'Validada';
    }
    value(2; Warning)
    {
        Caption = 'Con avisos';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
    value(4; Processed)
    {
        Caption = 'Procesada';
    }
}
