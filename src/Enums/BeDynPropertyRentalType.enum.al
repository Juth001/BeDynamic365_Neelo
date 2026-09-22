namespace BeDynamic.PropertyManagement;

enum 82501 "BeDyn Property Rental Type"
{
    Extensible = true;
    Caption = 'Tipo de alquiler';

    value(0; "Entire Property")
    {
        Caption = 'Propiedad completa';
    }
    value(1; "By Room")
    {
        Caption = 'Por subpropiedades';
    }
}
