namespace BeDynamic.PropertyManagement;

page 82514 "BeDyn Portal List"
{
    PageType = List;
    SourceTable = "BeDyn Portal";
    Caption = 'Portales';
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
                    ToolTip = 'Código del portal (p. ej. IDEALISTA, AIRBNB, BOOKING).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del portal.';
                }
            }
        }
    }
}
