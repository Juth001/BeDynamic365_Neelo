namespace BeDynamic.PleoImport;

page 82104 "BeDyn Pleo Purchaser Mapping"
{
    Caption = 'Mapeo Compradores Pleo';
    PageType = List;
    SourceTable = "BeDyn Pleo Purchaser Mapping";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Pleo Owner"; Rec."Pleo Owner")
                {
                    ApplicationArea = All;
                }
                field("Salesperson/Purch. Code"; Rec."Salesperson/Purch. Code")
                {
                    ApplicationArea = All;
                }
                field("Non-Deductible"; Rec."Non-Deductible")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
