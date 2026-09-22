namespace BeDynamic.PropertyManagement;

page 82517 "BeDyn Property Statuses"
{
    PageType = List;
    SourceTable = "BeDyn Property Status";
    Caption = 'Estados propiedad';
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
                    ToolTip = 'Código del estado (p. ej. ACTIVO, PUBLICADO, BAJA).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del estado.';
                }
            }
        }
    }
}
