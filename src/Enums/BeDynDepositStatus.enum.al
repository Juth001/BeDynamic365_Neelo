namespace BeDynamic.PropertyManagement;

enum 82513 "BeDyn Deposit Status"
{
    Extensible = true;
    Caption = 'Estado fianza';

    value(0; Pending)
    {
        Caption = 'Pendiente';
    }
    value(1; Collected)
    {
        Caption = 'Cobrada';
    }
    value(2; Returned)
    {
        Caption = 'Devuelta';
    }
    value(3; Retained)
    {
        Caption = 'Retenida';
    }
}
