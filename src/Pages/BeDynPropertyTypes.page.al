namespace BeDynamic.PropertyManagement;

page 82521 "BeDyn Property Types"
{
    PageType = List;
    SourceTable = "BeDyn Property Type";
    Caption = 'Tipos propiedad';
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
                    ToolTip = 'Código del tipo de propiedad (p. ej. APARTAMENTO, CASA, LOFT).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del tipo de propiedad.';
                }
            }
        }
    }
}
