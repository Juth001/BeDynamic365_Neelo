namespace BeDynamic.PortalImport;

using Microsoft.Sales.History;

page 82603 "BeDyn Portal Import Archive"
{
    Caption = 'Hist. Importación Portales de Venta';
    PageType = List;
    SourceTable = "BeDyn Portal Import Archive";
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
                field(Channel; Rec.Channel)
                {
                    ApplicationArea = All;
                }
                field("Transaction Date"; Rec."Transaction Date")
                {
                    ApplicationArea = All;
                }
                field("Row Type"; Rec."Row Type")
                {
                    ApplicationArea = All;
                }
                field("Reservation Code"; Rec."Reservation Code")
                {
                    ApplicationArea = All;
                }
                field(Guest; Rec.Guest)
                {
                    ApplicationArea = All;
                }
                field(Listing; Rec.Listing)
                {
                    ApplicationArea = All;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = All;
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = All;
                }
                field(Nights; Rec.Nights)
                {
                    ApplicationArea = All;
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = All;
                }
                field("Commission Amount"; Rec."Commission Amount")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Paid Out Amount"; Rec."Paid Out Amount")
                {
                    ApplicationArea = All;
                }
                field("Property Code"; Rec."Property Code")
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Warning Message"; Rec."Warning Message")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = All;
                }
                field("Archived Date"; Rec."Archived Date")
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
                ToolTip = 'Abre el documento registrado de la línea seleccionada.';

                trigger OnAction()
                begin
                    OpenPostedDocument();
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

    local procedure OpenPostedDocument()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NoDocMsg: Label 'La línea no tiene ningún documento registrado asociado.';
    begin
        if Rec."Posted Document No." <> '' then begin
            if SalesInvHeader.Get(Rec."Posted Document No.") then begin
                Page.Run(Page::"Posted Sales Invoice", SalesInvHeader);
                exit;
            end;
            // Los ajustes de resolución se registran como abono.
            if SalesCrMemoHeader.Get(Rec."Posted Document No.") then begin
                Page.Run(Page::"Posted Sales Credit Memo", SalesCrMemoHeader);
                exit;
            end;
        end;
        Message(NoDocMsg);
    end;
}
