namespace BeDynamic.PleoImport;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

page 82105 "BeDyn Pleo Expense Archive"
{
    Caption = 'Archivo Gastos Pleo';
    PageType = List;
    SourceTable = "BeDyn Pleo Expense Archive";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Batch Code"; Rec."Batch Code")
                {
                    ApplicationArea = All;
                }
                field("Expense Date"; Rec."Expense Date")
                {
                    ApplicationArea = All;
                }
                field("Receipt No."; Rec."Receipt No.")
                {
                    ApplicationArea = All;
                }
                field("Expense Type"; Rec."Expense Type")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Source Description"; Rec."Source Description")
                {
                    ApplicationArea = All;
                }
                field(Owner; Rec.Owner)
                {
                    ApplicationArea = All;
                }
                field(Note; Rec.Note)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Team; Rec.Team)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Expense ID"; Rec."Expense ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Receipt URL"; Rec."Receipt URL")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Project Code"; Rec."Project Code")
                {
                    ApplicationArea = All;
                }
                field("Cost Type Name"; Rec."Cost Type Name")
                {
                    ApplicationArea = All;
                }
                field("Pleo Vendor Name"; Rec."Pleo Vendor Name")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Mapped Vendor No."; Rec."Mapped Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = All;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = All;
                }
                field(CAPEX; Rec.CAPEX)
                {
                    ApplicationArea = All;
                }
                field(Extraordinary; Rec.Extraordinary)
                {
                    ApplicationArea = All;
                }
                field("Fixed Asset No."; Rec."Fixed Asset No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Warning Message"; Rec."Warning Message")
                {
                    ApplicationArea = All;
                }
                field("Created Document No."; Rec."Created Document No.")
                {
                    ApplicationArea = All;
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = All;
                }
                field("Payment Posted"; Rec."Payment Posted")
                {
                    ApplicationArea = All;
                }
                field("Archived Date Time"; Rec."Archived Date Time")
                {
                    ApplicationArea = All;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowDocument)
            {
                Caption = 'Ver documento';
                ApplicationArea = All;
                Image = Document;
                ToolTip = 'Abre el documento de compra creado o registrado de la línea seleccionada.';

                trigger OnAction()
                begin
                    OpenDocument();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';
                actionref(ShowDocument_Promoted; ShowDocument) { }
            }
        }
    }

    local procedure OpenDocument()
    var
        NoDocMsg: Label 'La línea no tiene ningún documento de compra asociado (los diarios se consultan desde los movimientos de contabilidad o banco).';
    begin
        if OpenPostedDocument() then
            exit;
        if OpenCreatedDocument() then
            exit;
        Message(NoDocMsg);
    end;

    local procedure OpenPostedDocument(): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        if Rec."Posted Document No." = '' then
            exit(false);
        if Rec.Amount < 0 then begin
            if not PurchInvHeader.Get(Rec."Posted Document No.") then
                exit(false);
            Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
            exit(true);
        end;
        if not PurchCrMemoHdr.Get(Rec."Posted Document No.") then
            exit(false);
        Page.Run(Page::"Posted Purchase Credit Memo", PurchCrMemoHdr);
        exit(true);
    end;

    local procedure OpenCreatedDocument(): Boolean
    var
        PurchHeader: Record "Purchase Header";
    begin
        if Rec."Created Document No." = '' then
            exit(false);
        if Rec.Amount < 0 then begin
            if not PurchHeader.Get(PurchHeader."Document Type"::Invoice, Rec."Created Document No.") then
                exit(false);
            Page.Run(Page::"Purchase Invoice", PurchHeader);
            exit(true);
        end;
        if not PurchHeader.Get(PurchHeader."Document Type"::"Credit Memo", Rec."Created Document No.") then
            exit(false);
        Page.Run(Page::"Purchase Credit Memo", PurchHeader);
        exit(true);
    end;
}
