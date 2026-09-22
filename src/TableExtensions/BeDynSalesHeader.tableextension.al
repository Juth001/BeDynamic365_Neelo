namespace Neelo.RecurringInvoicing;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Document;

/// <summary>
/// Management Bank source: set when the sales invoice is created.
/// </summary>
tableextension 81015 "BeDyn Sales Header" extends "Sales Header"
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
