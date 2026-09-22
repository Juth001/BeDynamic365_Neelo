namespace Neelo.RecurringInvoicing;

/// <summary>
/// Concept type (sales line type) used for REC / Extra.
/// Maps to the standard "Sales Line Type" enum.
/// </summary>
enum 81007 "BeDyn Billing Concept Type"
{
    Extensible = true;
    Caption = 'Billing Concept Type';

    value(0; "G/L Account")
    {
        Caption = 'G/L Account';
    }
    value(1; Item)
    {
        Caption = 'Item';
    }
    value(2; Resource)
    {
        Caption = 'Resource';
    }
}
