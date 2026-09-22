namespace BeDynamic.PropertyManagement;

table 82516 "BeDyn Amenity Type"
{
    Caption = 'Tipo amenity';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Amenity Types";
    DrillDownPageId = "BeDyn Amenity Types";

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
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        Amenity: Record "BeDyn Amenity";
    begin
        Amenity.SetRange("Amenity Type Code", "Code");
        if not Amenity.IsEmpty() then
            Error(InUseErr, "Code");
    end;

    var
        InUseErr: Label 'No se puede eliminar el tipo de amenity %1 porque hay amenities que lo utilizan.', Comment = '%1 = Código tipo amenity';
}
