namespace Neelo.RecurringInvoicing;

/// <summary>
/// Customer field used to locate the customer by Tax ID (CIF/NIF).
/// </summary>
enum 81008 "BeDyn NIF Source"
{
    Extensible = true;
    Caption = 'Tax ID Source';

    value(0; "VAT Registration No.")
    {
        Caption = 'VAT Registration No.';
    }
    value(1; "Custom NIF")
    {
        Caption = 'Custom Tax ID field';
    }
}
