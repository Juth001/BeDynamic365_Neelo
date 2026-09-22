namespace BeDynamic.PortalImport;

enum 82602 "BeDyn Portal Line Status"
{
    Extensible = true;
    Caption = 'Estado línea portal';

    value(0; Pending)
    {
        Caption = 'Pendiente';
    }
    value(1; Validated)
    {
        Caption = 'Validada';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
    value(4; Posted)
    {
        Caption = 'Registrada';
    }
    value(9; Skipped)
    {
        Caption = 'Omitida';
    }
}
