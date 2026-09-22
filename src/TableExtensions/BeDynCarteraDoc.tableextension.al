namespace Neelo.RecurringInvoicing;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;

// Confirmed against the environment symbols: the Spanish Cartera receivable document
// table is "Cartera Doc." (ID 7000002), namespace Microsoft.Finance.ReceivablesPayables.

/// <summary>
/// Management Bank on the Cartera receivable document (Spanish localization).
/// </summary>
tableextension 81018 "BeDyn Cartera Doc." extends "Cartera Doc."
{
    fields
    {
        field(81001; "Management Bank"; Code[20])
        {
            Caption = 'Management Bank';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account"."No.";
        }
    }
}
