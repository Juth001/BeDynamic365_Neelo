namespace Neelo.RecurringInvoicing;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.History;

// "Cartera Doc." (table 7000002), namespace Microsoft.Finance.ReceivablesPayables.

/// <summary>
/// Propagates the Management Bank to the Cartera receivable document (Spanish localization)
/// when it is created on posting. The value is read from the posted sales invoice header,
/// which carries the bank from the billing configuration used at import (via TransferFields).
///
/// Discriminator: "Cartera Doc.".Type = enum "Cartera Document Type"::Receivable (collections);
/// "Document No." holds the posted invoice number.
/// </summary>
codeunit 81022 "BeDyn Cartera Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Cartera Doc.", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CarteraDocOnBeforeInsert(var Rec: Record "Cartera Doc."; RunTrigger: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Rec.IsTemporary() then
            exit;
        // Receivable (customer) documents only.
        if Rec.Type <> Rec.Type::Receivable then
            exit;
        if Rec."Document No." = '' then
            exit;
        if SalesInvoiceHeader.Get(Rec."Document No.") then
            Rec."Management Bank" := SalesInvoiceHeader."Management Bank";
    end;
}
