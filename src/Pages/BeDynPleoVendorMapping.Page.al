namespace BeDynamic.PleoImport;

page 82102 "BeDyn Pleo Vendor Mapping"
{
    Caption = 'Mapeo Proveedores Pleo';
    PageType = List;
    SourceTable = "BeDyn Pleo Vendor Mapping";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Pleo Code"; Rec."Pleo Code")
                {
                    ApplicationArea = All;
                }
                field("Pleo Name"; Rec."Pleo Name")
                {
                    ApplicationArea = All;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
