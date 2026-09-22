namespace BeDynamic.PortalImport;

enum 82603 "BeDyn Portal Commission Mode"
{
    Extensible = true;
    Caption = 'Tratamiento comisiones portal';

    value(0; "G/L Account")
    {
        Caption = 'Cuenta contable';
    }
    value(1; Vendor)
    {
        Caption = 'Cargo a proveedor';
    }
}
