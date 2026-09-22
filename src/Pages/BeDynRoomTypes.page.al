namespace BeDynamic.PropertyManagement;

page 82522 "BeDyn Room Types"
{
    PageType = List;
    SourceTable = "BeDyn Room Type";
    Caption = 'Tipos subpropiedad';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código del tipo de subpropiedad (p. ej. PRIVATE ROOM, ENTIRE HOME).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del tipo de subpropiedad.';
                }
                field("Property Type Code"; Rec."Property Type Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
