namespace BeDynamic.CleaningImport;

enum 82700 "BeDyn Cleaning Line Status"
{
    Extensible = false;
    Caption = 'Estado línea limpieza';

    value(0; Pending)
    {
        Caption = 'Pendiente';
    }
    value(1; Error)
    {
        Caption = 'Error';
    }
    value(2; Validated)
    {
        Caption = 'Validada';
    }
    value(3; Posted)
    {
        Caption = 'Reclasificada';
    }
}
