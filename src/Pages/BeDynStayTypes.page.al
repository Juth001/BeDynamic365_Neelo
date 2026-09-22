namespace BeDynamic.PropertyManagement;

page 82524 "BeDyn Stay Types"
{
    PageType = List;
    SourceTable = "BeDyn Stay Type";
    Caption = 'Tipos estancia';
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
                    ToolTip = 'Código del tipo de estancia (p. ej. CORTA, MEDIA, LARGA).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del tipo de estancia.';
                }
            }
        }
    }
}
