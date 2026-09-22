namespace BeDynamic.PropertyManagement;

page 82525 "BeDyn Amenity Types"
{
    PageType = List;
    SourceTable = "BeDyn Amenity Type";
    Caption = 'Tipos amenity';
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
                    ToolTip = 'Código del tipo de amenity (p. ej. ELECTRODOMÉSTICO, MOBILIARIO).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del tipo de amenity.';
                }
            }
        }
    }
}
