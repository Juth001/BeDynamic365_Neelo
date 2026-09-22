namespace Neelo.RecurringInvoicing;

using Microsoft.Sales.Receivables;

/// <summary>
/// Shows the Management Bank column on the receivable documents selection list, so the
/// user can sort/filter and pick only the documents that match the remittance bank.
/// </summary>
pageextension 81023 "BeDyn Receiv. Cartera Docs" extends "Receivables Cartera Docs"
{
    layout
    {
        addafter("Account No.")
        {
            field("Management Bank"; Rec."Management Bank")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the Management Bank of the document. Use it to select only documents that match the remittance bank.';
            }
        }
    }

    trigger OnOpenPage()
    var
        Context: Codeunit "BeDyn Remittance Context";
        BankNo: Code[20];
    begin
        // When opened to insert documents into a bill group, pre-filter by the bill group's bank.
        BankNo := Context.GetBank();
        if BankNo <> '' then
            Rec.SetRange("Management Bank", BankNo);
    end;
}
