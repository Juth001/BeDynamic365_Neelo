namespace BeDynamic.PortalImport;

enum 82600 "BeDyn Portal Channel"
{
    Extensible = true;
    Caption = 'Canal portal de venta';

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Airbnb)
    {
        Caption = 'Airbnb';
    }
    value(2; Booking)
    {
        Caption = 'Booking';
    }
    value(3; Idealista)
    {
        Caption = 'Idealista';
    }
    value(4; MeIT)
    {
        Caption = 'MeIT';
    }
    value(5; HousingAnywhere)
    {
        Caption = 'Housing Anywhere';
    }
    value(6; Spotahome)
    {
        Caption = 'Spotahome';
    }
    value(7; Hostify)
    {
        Caption = 'Hostify';
    }
}
