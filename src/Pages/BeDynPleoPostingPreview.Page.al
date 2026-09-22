namespace BeDynamic.PleoImport;

page 82106 "BeDyn Pleo Posting Preview"
{
    Caption = 'Vista previa del registro Pleo';
    PageType = List;
    SourceTable = "BeDyn Pleo Posting Preview";
    SourceTableTemporary = true;
    Editable = false;
    UsageCategory = None;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Operation; Rec.Operation)
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Receipt No."; Rec."Receipt No.")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("External Doc. No."; Rec."External Doc. No.")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Account Kind"; Rec."Account Kind")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Project Code"; Rec."Project Code")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field("Action Text"; Rec."Action Text")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
                field(Warning; Rec.Warning)
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                }
            }
        }
    }

    var
        LineStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec.Warning <> '' then
            LineStyle := 'Ambiguous'
        else
            LineStyle := 'Standard';
    end;
}
