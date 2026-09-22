namespace BeDynamic.PortalImport;

page 82602 "BeDyn Portal Listing Mapping"
{
    Caption = 'Mapeo Alojamientos Portales';
    PageType = List;
    SourceTable = "BeDyn Portal Listing Mapping";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Portal Code"; Rec."Portal Code")
                {
                    ApplicationArea = All;
                }
                field("Listing Key"; Rec."Listing Key")
                {
                    ApplicationArea = All;
                }
                field("Listing Name"; Rec."Listing Name")
                {
                    ApplicationArea = All;
                }
                field("Property Code"; Rec."Property Code")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateVariantEditable();
                    end;
                }
                field("Property Name"; Rec."Property Name")
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Editable = VariantEditable;
                }
            }
        }
    }

    var
        VariantEditable: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateVariantEditable();
    end;

    local procedure UpdateVariantEditable()
    begin
        VariantEditable := Rec."Property Code" <> '';
    end;
}
