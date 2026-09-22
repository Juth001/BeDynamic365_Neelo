namespace Neelo.RecurringInvoicing;

/// <summary>
/// Invoice grouping mode per customer.
/// </summary>
enum 81006 "BeDyn Invoice Grouping"
{
    Extensible = true;
    Caption = 'Invoice Grouping';

    value(0; Grouped)
    {
        Caption = 'Grouped';
    }
    value(1; Individual)
    {
        Caption = 'Individual';
    }
}
