namespace Neelo.RecurringInvoicing;

using Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Shows the Management Bank column on the "Cartera Documents" worksheet (7000003), which is
/// the page the Spanish Cartera opens to select receivable documents for a bill group. The
/// actual filtering by the remittance bank is enforced in "Remittance Subscribers" via the
/// OnInsertReceivableDocsOnAfterSetFilters event; this column lets the user see/sort by it.
/// </summary>
pageextension 81026 "BeDyn Cartera Documents" extends "Cartera Documents"
{
    layout
    {
        addafter("Account No.")
        {
            field("Management Bank"; Rec."Management Bank")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the Management Bank of the document. The selection is filtered to the remittance bank.';
            }
        }
    }
}
