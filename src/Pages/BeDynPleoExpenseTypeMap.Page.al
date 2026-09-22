namespace BeDynamic.PleoImport;

page 82103 "BeDyn Pleo Expense Type Map"
{
    Caption = 'Mapeo Categorías Pleo';
    PageType = List;
    SourceTable = "BeDyn Pleo Expense Type Map";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Pleo Category"; Rec."Pleo Category")
                {
                    ApplicationArea = All;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = All;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                }
                field(CAPEX; Rec.CAPEX)
                {
                    ApplicationArea = All;
                }
                field("FA Class Code"; Rec."FA Class Code")
                {
                    ApplicationArea = All;
                    Editable = Rec.CAPEX;
                }
                field("FA Subclass Code"; Rec."FA Subclass Code")
                {
                    ApplicationArea = All;
                    Editable = Rec.CAPEX;
                }
            }
        }
    }
}
