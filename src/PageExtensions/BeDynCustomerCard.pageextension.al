namespace Neelo.RecurringInvoicing;

using Microsoft.Sales.Customer;

/// <summary>
/// Adds the recurring invoicing configuration (billing codes) as related data on the
/// Customer card, opened from the "Customer" navigation group (like the other related lists).
/// </summary>
pageextension 81019 "BeDyn Customer Card" extends "Customer Card"
{
    actions
    {
        addlast("&Customer")
        {
            action(RecurringInvoicing)
            {
                Caption = 'Recurring Invoicing';
                ToolTip = 'Opens the recurring invoicing configuration (billing codes) for this customer.';
                Image = Currencies;
                ApplicationArea = All;
                RunObject = page "BeDyn Customer Billing";
                RunPageLink = "Customer No." = field("No.");
            }
        }
    }
}
