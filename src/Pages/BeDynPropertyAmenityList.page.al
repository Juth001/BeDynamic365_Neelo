namespace BeDynamic.PropertyManagement;

page 82530 "BeDyn Property Amenity List"
{
    PageType = List;
    SourceTable = "BeDyn Property Amenity";
    Caption = 'Amenities';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad a la que pertenece el amenity.';
                    Visible = false;
                }
                field(Location; Rec.Location)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si el amenity pertenece a una zona común o a una subpropiedad.';
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Subpropiedad a la que pertenece el amenity. Solo aplica si la ubicación es Subpropiedad.';
                }
                field("Amenity Code"; Rec."Amenity Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código del amenity.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del amenity. Se propone la del amenity y se puede modificar.';
                }
                field("Amenity Type Code"; Rec."Amenity Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tipo al que pertenece el amenity.';
                }
                field(Brand; Rec.Brand)
                {
                    ApplicationArea = All;
                    ToolTip = 'Marca del amenity.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de serie del amenity.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado del amenity (nuevo, bueno, regular, averiado, en reparación o baja).';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec.GetFilter("Room No.") <> '' then
            Rec.Validate("Room No.", CopyStr(Rec.GetFilter("Room No."), 1, MaxStrLen(Rec."Room No.")));
    end;
}
