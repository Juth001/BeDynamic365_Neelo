namespace BeDynamic.PleoImport;

enum 82101 "BeDyn Pleo Line Status"
{
    Extensible = true;
    Caption = 'Estado línea Pleo';

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
    value(3; Created)
    {
        Caption = 'Documento creado';
    }
    value(4; Posted)
    {
        Caption = 'Registrada';
    }
    value(5; Paid)
    {
        Caption = 'Registrada y pagada';
    }
    value(9; Skipped)
    {
        Caption = 'Omitida';
    }
}
