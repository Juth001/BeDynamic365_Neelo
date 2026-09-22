namespace BeDynamic.PleoImport;

enum 82102 "BeDyn Pleo Post Action"
{
    Extensible = true;
    Caption = 'Acción tras importar';

    value(0; "Draft Only")
    {
        Caption = 'Solo borrador';
    }
    value(1; Post)
    {
        Caption = 'Registrar';
    }
    value(2; "Post & Pay")
    {
        Caption = 'Registrar y pagar';
    }
}
