namespace BeDynamic.PropertyManagement;

enum 82500 "BeDyn Contract Type"
{
    Extensible = true;
    Caption = 'Tipo de contrato';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Exploitation)
    {
        Caption = 'Explotación';
    }
    value(2; Management)
    {
        Caption = 'Gestión';
    }
}
