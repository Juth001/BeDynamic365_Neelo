namespace Neelo.RecurringInvoicing;

using BeDynamic.PropertyManagement;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Review/validation page for the imported CSV lines.
/// </summary>
page 81003 "BeDyn Invoice Import Buffer"
{
    Caption = 'Invoice Import';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "BeDyn Invoice Import Buffer";
    InsertAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Import Batch Code"; Rec."Import Batch Code")
                {
                    ToolTip = 'Specifies the import batch the line belongs to.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the line number within the batch.';
                }
                field("Billing Code"; Rec."Billing Code")
                {
                    ToolTip = 'Specifies the billing code read from column 1 of the CSV; it selects the customer billing configuration to use.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ToolTip = 'Specifies the Tax ID (CIF/NIF) read from the CSV.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the posting date read from the CSV; it becomes the posting date of the generated invoice.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ToolTip = 'Specifies the external document number read from the CSV; it becomes the external document number of the generated invoice.';
                }
                field("Property Code"; Rec."Property Code")
                {
                    ToolTip = 'Specifies the property read from the individuals CSV; it is invoiced as the item of the line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the room read from the individuals CSV; it is assigned as the item variant of the line.';
                }
                field("Business Line Code"; Rec."Business Line Code")
                {
                    ToolTip = 'Specifies the business line read from the individuals CSV; the dimension value is stamped on the header and lines of the generated invoice.';
                }
                field("Channel Code"; Rec."Channel Code")
                {
                    ToolTip = 'Specifies the channel read from the individuals CSV; the dimension value is stamped on the header and lines of the generated invoice.';
                }
                field("Unit Code"; Rec."Unit Code")
                {
                    ToolTip = 'Specifies the unit read from the individuals CSV; the dimension value is stamped on the header and lines of the generated invoice.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ToolTip = 'Specifies the customer resolved after validation.';
                }
                field("BC Customer No."; Rec."BC Customer No.")
                {
                    ToolTip = 'Specifies the BC customer number read from the CSV (BC ID column). Only used to choose the customer when the Tax ID matches more than one.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description shown on the invoice line.';
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the amount to invoice.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the VAT product posting group read from the CSV; when set, it is assigned to the invoice line instead of being inherited from the item/account.';
                }
                field("Is Comment"; Rec."Is Comment")
                {
                    ToolTip = 'Specifies whether the line is imported as a comment (no amount) on a grouped invoice.';
                }
                field("Invoice Grouping"; Rec."Invoice Grouping")
                {
                    ToolTip = 'Specifies the grouping mode copied from the customer.';
                }
                field("Management Bank"; Rec."Management Bank")
                {
                    ToolTip = 'Specifies the Management Bank copied from the customer.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the line status (Pending / Validated / Error / Processed).';
                    StyleExpr = StatusStyle;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ToolTip = 'Specifies the validation error detail.';
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ToolTip = 'Specifies the document number generated after posting: the invoice, or the deposit for deposit billing codes.';
                }
                field("Deposit No."; Rec."Deposit No.")
                {
                    ToolTip = 'Specifies the deposit created for the line when the billing code is a deposit. Its number is also the document number of the posted G/L entries.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Import)
            {
                Caption = 'Import CSV';
                ToolTip = 'Selects a CSV file and creates a new batch of pending lines.';
                Image = Import;
                ApplicationArea = All;

                trigger OnAction()
                var
                    ImportMgt: Codeunit "BeDyn Import Mgt.";
                    BatchCode: Code[20];
                begin
                    BatchCode := ImportMgt.ImportCSV();
                    if BatchCode <> '' then begin
                        Rec.SetRange("Import Batch Code", BatchCode);
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(ImportIndividuals)
            {
                Caption = 'Import Individuals CSV';
                ToolTip = 'Selects a CSV file with the individuals template layout (property, room and business line columns) and creates a new batch of pending lines.';
                Image = ImportExcel;
                ApplicationArea = All;

                trigger OnAction()
                var
                    ImportMgt: Codeunit "BeDyn Import Mgt.";
                    BatchCode: Code[20];
                begin
                    BatchCode := ImportMgt.ImportIndividualsCSV();
                    if BatchCode <> '' then begin
                        Rec.SetRange("Import Batch Code", BatchCode);
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(ValidateBatch)
            {
                Caption = 'Validate Batch';
                ToolTip = 'Validates all lines in the batch of the selected line.';
                Image = Approve;
                ApplicationArea = All;

                trigger OnAction()
                var
                    ValidationMgt: Codeunit "BeDyn Validation Mgt.";
                begin
                    if Rec."Import Batch Code" = '' then
                        Error(SelectLineErr);
                    ValidationMgt.ValidateBatch(Rec."Import Batch Code");
                    CurrPage.Update(false);
                end;
            }
            action(PostBatch)
            {
                Caption = 'Post Batch';
                ToolTip = 'Generates and posts invoices for the validated lines in the batch.';
                Image = PostDocument;
                ApplicationArea = All;

                trigger OnAction()
                var
                    PostingMgt: Codeunit "BeDyn Posting Mgt.";
                begin
                    if Rec."Import Batch Code" = '' then
                        Error(SelectLineErr);
                    PostingMgt.PostBatch(Rec."Import Batch Code");
                    CurrPage.Update(false);
                end;
            }
            action(ProcessSelection)
            {
                Caption = 'Process Selected Lines';
                ToolTip = 'Generates and posts invoices for the selected validated lines.';
                Image = PostOrder;
                ApplicationArea = All;

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Invoice Import Buffer";
                    PostingMgt: Codeunit "BeDyn Posting Mgt.";
                begin
                    CurrPage.SetSelectionFilter(BufferSel);
                    PostingMgt.PostSelection(BufferSel);
                    CurrPage.Update(false);
                end;
            }
            action(ArchiveProcessed)
            {
                Caption = 'Archive Processed Lines';
                ToolTip = 'Moves the processed lines (posted or ignored) within the current filters to the import archive, cleaning the worksheet.';
                Image = Archive;
                ApplicationArea = All;

                trigger OnAction()
                var
                    BufferSel: Record "BeDyn Invoice Import Buffer";
                    ImportMgt: Codeunit "BeDyn Import Mgt.";
                begin
                    if not Confirm(ArchiveQst, true) then
                        exit;
                    BufferSel.CopyFilters(Rec);
                    Message(ArchivedMsg, ImportMgt.ArchiveProcessed(BufferSel));
                    CurrPage.Update(false);
                end;
            }
            action(DeleteBatch)
            {
                Caption = 'Delete Batch';
                ToolTip = 'Deletes all the lines of the selected batch.';
                Image = Delete;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Buffer: Record "BeDyn Invoice Import Buffer";
                begin
                    if Rec."Import Batch Code" = '' then
                        Error(SelectLineErr);
                    if not Confirm(DeleteBatchQst, false, Rec."Import Batch Code") then
                        exit;
                    Buffer.SetRange("Import Batch Code", Rec."Import Batch Code");
                    Buffer.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
            action(CreateCustomer)
            {
                Caption = 'Create Customer';
                ToolTip = 'Creates a new customer (asks which template to use if any customer templates exist) and opens the customer card.';
                Image = NewCustomer;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Customer: Record Customer;
                    CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
                begin
                    if CustomerTemplMgt.InsertCustomerFromTemplate(Customer) then
                        Page.Run(Page::"Customer Card", Customer);
                end;
            }
        }
        area(Navigation)
        {
            action(OpenArchive)
            {
                Caption = 'Import Archive';
                ToolTip = 'Opens the archive of processed import lines.';
                Image = Archive;
                ApplicationArea = All;
                RunObject = page "BeDyn Invoice Import Archive";
            }
            action(ShowAll)
            {
                Caption = 'Show All Batches';
                ToolTip = 'Removes the batch filter and shows all lines.';
                Image = ClearFilter;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetRange("Import Batch Code");
                    CurrPage.Update(false);
                end;
            }
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
                        else begin
                            // A draft posted by hand after the import: the line keeps the
                            // draft no., which the posted invoice carries as pre-assigned no.
                            SalesInvoiceHeader.SetCurrentKey("Pre-Assigned No.");
                            SalesInvoiceHeader.SetRange("Pre-Assigned No.", Rec."Posted Document No.");
                            if SalesInvoiceHeader.FindLast() then
                                Page.Run(Page::"Posted Sales Invoice", SalesInvoiceHeader)
                            else
                                Error(NoDocumentErr);
                        end;
                end;
            }
        }
    }

    var
        StatusStyle: Text;
        SelectLineErr: Label 'Select a line with a batch to continue.';
        DeleteBatchQst: Label 'Delete all lines of batch %1?', Comment = '%1 = batch';
        ArchiveQst: Label 'Move the processed lines (posted or ignored) within the current filters to the archive?';
        ArchivedMsg: Label '%1 lines archived.', Comment = '%1 = line count';
        NoDocumentErr: Label 'There is no generated document for this line yet.';

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::Validated:
                StatusStyle := 'Favorable';
            Rec.Status::Posted:
                StatusStyle := 'Strong';
            Rec.Status::Ignored:
                StatusStyle := 'Subordinate';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
