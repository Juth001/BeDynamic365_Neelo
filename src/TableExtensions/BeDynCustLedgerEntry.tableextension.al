namespace Neelo.RecurringInvoicing;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Receivables;

/// <summary>
/// Management Bank on the customer ledger entries.
/// </summary>
tableextension 81017 "BeDyn Cust. Ledger Entry" extends "Cust. Ledger Entry"
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
