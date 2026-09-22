namespace BeDynamic.ReservationImport;

enum 82801 "BeDyn Res. Duplicate Action"
{
    // Qué hacer cuando el fichero trae una reserva que ya está cargada, es decir,
    // con un Id externo que ya existe en Business Central.

    Extensible = true;
    Caption = 'Reservas ya cargadas';

    value(0; Warn)
    {
        Caption = 'Avisar sin modificar';
    }
    value(1; Update)
    {
        Caption = 'Actualizar';
    }
    value(2; Fail)
    {
        Caption = 'Dar error';
    }
}
