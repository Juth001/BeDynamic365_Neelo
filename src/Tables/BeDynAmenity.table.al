namespace BeDynamic.PropertyManagement;

table 82517 "BeDyn Amenity"
{
    Caption = 'Amenity';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Amenities";
    DrillDownPageId = "BeDyn Amenities";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Código';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Descripción';
        }
        field(3; "Amenity Type Code"; Code[20])
        {
            Caption = 'Cód. tipo amenity';
            TableRelation = "BeDyn Amenity Type";
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Amenity Type Code")
        {
        }
    }

    trigger OnDelete()
    var
        PropertyAmenity: Record "BeDyn Property Amenity";
    begin
        PropertyAmenity.SetRange("Amenity Code", "Code");
        if not PropertyAmenity.IsEmpty() then
            Error(InUseErr, "Code");
    end;

    var
        InUseErr: Label 'No se puede eliminar el amenity %1 porque está asignado a propiedades o subpropiedades.', Comment = '%1 = Código amenity';
}
