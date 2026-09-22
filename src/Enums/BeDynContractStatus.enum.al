namespace BeDynamic.PropertyManagement;

enum 82503 "BeDyn Contract Status"
{
    Extensible = true;
    Caption = 'Estado de contrato';

    value(0; Draft)
    {
        Caption = 'Borrador';
    }
    value(1; Active)
    {
        Caption = 'Activo';
    }
    value(2; Closed)
    {
        Caption = 'Finalizado';
    }
}
