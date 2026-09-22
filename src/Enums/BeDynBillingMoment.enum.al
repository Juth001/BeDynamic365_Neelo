namespace BeDynamic.PropertyManagement;

enum 82512 "BeDyn Billing Moment"
{
    Extensible = true;
    Caption = 'Momento de facturación';

    value(0; "At Check-In")
    {
        Caption = 'Al check-in (prepago)';
    }
    value(1; "At Check-Out")
    {
        Caption = 'Al check-out';
    }
}
