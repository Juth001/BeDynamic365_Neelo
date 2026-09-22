namespace BeDynamic.PropertyManagement;

enum 82540 "BeDyn Property Text Type"
{
    Extensible = true;
    Caption = 'Tipo de texto de propiedad';

    value(0; Marketing)
    {
        Caption = 'Texto de marketing';
    }
    value(1; "House Rules")
    {
        Caption = 'Normas de la casa';
    }
    value(2; Transit)
    {
        Caption = 'Cómo llegar (transit)';
    }
    value(3; Access)
    {
        Caption = 'Acceso (access)';
    }
}
