namespace Neelo.RecurringInvoicing;

using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

/// <summary>
/// Propagates the Management Bank down to the customer ledger entries on posting.
/// The value flows from the billing configuration to the invoice (Sales Header, and via
/// TransferFields to the posted Sales Invoice Header). Since the posted invoice header is
/// inserted before the customer entry is created, it is a reliable source.
/// </summary>
codeunit 81012 "BeDyn Posting Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CustLedgerEntryOnBeforeInsert(var Rec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."Document No." = '' then
            exit;
        if SalesInvoiceHeader.Get(Rec."Document No.") then
            Rec."Management Bank" := SalesInvoiceHeader."Management Bank";
    end;
}
