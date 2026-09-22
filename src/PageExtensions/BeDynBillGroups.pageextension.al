namespace Neelo.RecurringInvoicing;

using Microsoft.Sales.Receivables;

/// <summary>
/// Captures the Management Bank (Bank Account No.) of the bill group being edited so the
/// receivable documents selection list can be pre-filtered by it.
/// </summary>
pageextension 81025 "BeDyn Bill Groups" extends "Bill Groups"
{
    trigger OnAfterGetCurrRecord()
    var
        Context: Codeunit "BeDyn Remittance Context";
    begin
        Context.SetBank(Rec."Bank Account No.");
    end;

    trigger OnClosePage()
    var
        Context: Codeunit "BeDyn Remittance Context";
    begin
        Context.ClearBank();
    end;
}
