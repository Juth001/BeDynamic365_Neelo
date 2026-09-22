namespace BeDynamic.PropertyManagement;

enum 82514 "BeDyn Deposit Billing Method"
{
    Extensible = true;
    Caption = 'Cobro de la fianza';

    value(0; "First Invoice")
    {
        Caption = 'En la primera factura (línea sin IVA)';
    }
    value(1; "Separate Collection")
    {
        Caption = 'Cobro aparte (sin factura)';
    }
}
