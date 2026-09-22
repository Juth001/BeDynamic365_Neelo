namespace BeDynamic.PropertyManagement;

enum 82510 "BeDyn Amenity Status"
{
    Extensible = true;
    Caption = 'Estado amenity';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; New)
    {
        Caption = 'Nuevo';
    }
    value(2; Good)
    {
        Caption = 'Bueno';
    }
    value(3; Fair)
    {
        Caption = 'Regular';
    }
    value(4; Damaged)
    {
        Caption = 'Averiado';
    }
    value(5; "In Repair")
    {
        Caption = 'En reparación';
    }
    value(6; Retired)
    {
        Caption = 'Baja';
    }
}
