namespace Neelo.RecurringInvoicing;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Enforces the Management Bank filter on the collection remittance (Spanish Cartera).
///
/// Primary hook: Codeunit "CarteraManagement".InsertReceivableDocs raises the
/// IntegrationEvent OnInsertReceivableDocsOnAfterSetFilters(var "Cartera Doc."; "Bill Group")
/// right after applying its own filters and BEFORE showing the document selection page
/// ("Cartera Documents", 7000003) / inserting the documents. We add a filter so that only
/// documents whose Management Bank is blank or equal to the bill group's bank are shown and
/// inserted. This both restricts what the user sees and what ends up in the group.
///
/// Safety net: OnAfterInsertReceivableDocs(var "Cartera Doc."; var "Bill Group") fires after
/// the documents are inserted; any document whose Management Bank is set and differs from the
/// bill group's bank is removed from the group (its "Bill Gr./Pmt. Order No." is cleared).
/// This also covers documents added through other paths. Documents without a Management Bank
/// are left untouched.
/// </summary>
codeunit 81013 "BeDyn Remittance Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CarteraManagement", 'OnInsertReceivableDocsOnAfterSetFilters', '', false, false)]
    local procedure CarteraMgtOnInsertReceivableDocsOnAfterSetFilters(var CarteraDoc: Record "Cartera Doc."; BillGroup: Record "Bill Group")
    begin
        if BillGroup."Bank Account No." = '' then
            exit;

        // Show/insert only documents with no Management Bank or the bill group's own bank.
        CarteraDoc.SetFilter("Management Bank", '%1|%2', '', BillGroup."Bank Account No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CarteraManagement", 'OnAfterInsertReceivableDocs', '', false, false)]
    local procedure CarteraMgtOnAfterInsertReceivableDocs(var CarteraDoc: Record "Cartera Doc."; var BillGroup: Record "Bill Group")
    var
        Doc: Record "Cartera Doc.";
    begin
        if BillGroup."Bank Account No." = '' then
            exit;

        // Re-scan the bill group documents (robust whether the event fires per document
        // or once at the end) and drop those managed by a different bank.
        Doc.SetRange(Type, Doc.Type::Receivable);
        Doc.SetRange("Bill Gr./Pmt. Order No.", BillGroup."No.");
        Doc.SetFilter("Management Bank", '<>%1&<>%2', '', BillGroup."Bank Account No.");
        if Doc.FindSet() then
            repeat
                Doc."Bill Gr./Pmt. Order No." := '';
                Doc.Modify();
            until Doc.Next() = 0;
    end;
}
