namespace Neelo.RecurringInvoicing;

using Microsoft.Sales.Document;

/// <summary>
/// Shows the Management Bank on the sales invoice header.
/// </summary>
pageextension 81020 "BeDyn Sales Invoice" extends "Sales Invoice"
{
    layout
    {
        addlast("Invoice Details")
        {
            field("Management Bank"; Rec."Management Bank")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the bank that manages the collection. It is propagated to Cartera to filter the remittance.';
            }
        }
    }
}
