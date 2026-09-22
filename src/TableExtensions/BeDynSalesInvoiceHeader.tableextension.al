namespace Neelo.RecurringInvoicing;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.History;

/// <summary>
/// Management Bank on the posted sales invoice history.
/// </summary>
tableextension 81016 "BeDyn Sales Invoice Header" extends "Sales Invoice Header"
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
