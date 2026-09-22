namespace BeDynamic.PropertyManagement;

enum 82504 "BeDyn Price Basis"
{
    Extensible = true;
    Caption = 'Base de precio';

    value(0; "Per Night")
    {
        Caption = 'Por noche';
    }
    value(1; "Per Month")
    {
        Caption = 'Por mes';
    }
}
