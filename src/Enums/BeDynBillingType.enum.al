namespace Neelo.RecurringInvoicing;

/// <summary>
/// Billing classification of a customer billing configuration row (informational):
/// recurring vs. one-off (extra).
/// </summary>
enum 81004 "BeDyn Billing Type"
{
    Extensible = true;
    Caption = 'Billing Type';

    value(0; Recurring)
    {
        Caption = 'Recurring';
    }
    value(1; Extra)
    {
        Caption = 'Extra';
    }
}
