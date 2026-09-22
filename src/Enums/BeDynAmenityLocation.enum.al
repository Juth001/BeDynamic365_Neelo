namespace BeDynamic.PropertyManagement;

enum 82511 "BeDyn Amenity Location"
{
    Extensible = true;
    Caption = 'Ubicación amenity';

    value(0; "Common Area")
    {
        Caption = 'Zona común';
    }
    value(1; Room)
    {
        Caption = 'Subpropiedad';
    }
}
