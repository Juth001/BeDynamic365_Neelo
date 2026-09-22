namespace Neelo.RecurringInvoicing;

/// <summary>
/// Status of each import buffer line.
/// </summary>
enum 81005 "BeDyn Buffer Status"
{
    Extensible = true;
    Caption = 'Buffer Status';

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Validated)
    {
        Caption = 'Validated';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
    value(3; Posted)
    {
        Caption = 'Processed';
    }
    value(4; Ignored)
    {
        Caption = 'Ignored';
    }
}
