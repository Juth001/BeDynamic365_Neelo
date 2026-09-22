namespace BeDynamic.PropertyManagement;

page 82526 "BeDyn Amenities"
{
    PageType = List;
    SourceTable = "BeDyn Amenity";
    Caption = 'Amenities';
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
                    ToolTip = 'Código del amenity (p. ej. TV, NEVERA, SECADOR).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del amenity.';
                }
                field("Amenity Type Code"; Rec."Amenity Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tipo al que pertenece el amenity.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(AmenityTypes)
            {
                ApplicationArea = All;
                Caption = 'Tipos amenity';
                Image = Category;
                RunObject = page "BeDyn Amenity Types";
                ToolTip = 'Ver o editar los tipos de amenity.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(AmenityTypes_Promoted; AmenityTypes)
                {
                }
            }
        }
    }
}
