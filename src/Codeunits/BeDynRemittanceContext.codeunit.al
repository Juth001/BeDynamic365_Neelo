namespace Neelo.RecurringInvoicing;

/// <summary>
/// Session-scoped context that carries the Management Bank of the bill group the user is
/// currently editing, so the receivable documents selection list can be pre-filtered by it.
/// Set from the "Bill Groups" page and read by the "Receivables Cartera Docs" page extension.
/// </summary>
codeunit 81024 "BeDyn Remittance Context"
{
    SingleInstance = true;

    var
        CurrentBank: Code[20];

    procedure SetBank(BankNo: Code[20])
    begin
        CurrentBank := BankNo;
    end;

    procedure GetBank(): Code[20]
    begin
        exit(CurrentBank);
    end;

    procedure ClearBank()
    begin
        Clear(CurrentBank);
    end;
}
