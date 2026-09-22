namespace Neelo.RecurringInvoicing;

using BeDynamic.PropertyManagement;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Read-only archive of processed invoice import lines.
/// </summary>
page 81006 "BeDyn Invoice Import Archive"
{
    Caption = 'Invoice Import Archive';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "BeDyn Invoice Import Archive";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Import Batch Code"; Rec."Import Batch Code")
                {
                    ToolTip = 'Specifies the import batch the line belonged to.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the line number within the batch.';
                }
                field("Billing Code"; Rec."Billing Code")
                {
                    ToolTip = 'Specifies the billing code read from the CSV.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the posting date read from the CSV.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ToolTip = 'Specifies the customer resolved at validation.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ToolTip = 'Specifies the external document number (the property in the individuals layout).';
                }
                field("Property Code"; Rec."Property Code")
                {
                    ToolTip = 'Specifies the property read from the individuals CSV.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the room read from the individuals CSV.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the line.';
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the amount of the line.';
                }
                field("Business Line Code"; Rec."Business Line Code")
                {
                    ToolTip = 'Specifies the business line read from the CSV.';
                }
                field("Channel Code"; Rec."Channel Code")
                {
                    ToolTip = 'Specifies the channel read from the CSV.';
                }
                field("Unit Code"; Rec."Unit Code")
                {
                    ToolTip = 'Specifies the unit read from the CSV.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the status the line had when it was archived.';
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ToolTip = 'Specifies the document generated for the line: the invoice, or the deposit for deposit billing codes.';
                }
                field("Deposit No."; Rec."Deposit No.")
                {
                    ToolTip = 'Specifies the deposit created for the line when the billing code is a deposit.';
                }
                field("Archived At"; Rec."Archived At")
                {
                    ToolTip = 'Specifies when the line was archived.';
                }
                field("Archived By"; Rec."Archived By")
                {
                    ToolTip = 'Specifies who archived the line.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(NavigateDocument)
            {
                Caption = 'Navigate to Generated Document';
                ToolTip = 'Opens the document generated for the selected line: the invoice (posted or draft), or the deposit card for deposit lines.';
                Image = Navigate;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Deposit: Record "BeDyn Deposit";
                    SalesInvoiceHeader: Record "Sales Invoice Header";
                    SalesHeader: Record "Sales Header";
                begin
                    if Rec."Deposit No." <> '' then begin
                        Deposit.Get(Rec."Deposit No.");
                        Page.Run(Page::"BeDyn Deposit Card", Deposit);
                        exit;
                    end;
                    if Rec."Posted Document No." = '' then
                        Error(NoDocumentErr);
                    if SalesInvoiceHeader.Get(Rec."Posted Document No.") then
                        Page.Run(Page::"Posted Sales Invoice", SalesInvoiceHeader)
                    else
                        if SalesHeader.Get(SalesHeader."Document Type"::Invoice, Rec."Posted Document No.") then
                            Page.Run(Page::"Sales Invoice", SalesHeader)
                        else
                            Error(NoDocumentErr);
                end;
            }
        }
    }

    var
        NoDocumentErr: Label 'There is no generated document for this line.';
}
