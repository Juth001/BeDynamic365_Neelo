namespace BeDynamic.PropertyManagement;

table 82513 "BeDyn Property Type"
{
    Caption = 'Tipo propiedad';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Property Types";
    DrillDownPageId = "BeDyn Property Types";

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
        Property: Record "BeDyn Property";
        RoomType: Record "BeDyn Room Type";
    begin
        Property.SetRange("Property Type Code", "Code");
        if not Property.IsEmpty() then
            Error(InUseErr, "Code");
        RoomType.SetRange("Property Type Code", "Code");
        if not RoomType.IsEmpty() then
            Error(RoomTypeInUseErr, "Code");
    end;

    var
        InUseErr: Label 'No se puede eliminar el tipo de propiedad %1 porque hay propiedades que lo utilizan.', Comment = '%1 = Código tipo propiedad';
        RoomTypeInUseErr: Label 'No se puede eliminar el tipo de propiedad %1 porque hay tipos de subpropiedad que lo utilizan.', Comment = '%1 = Código tipo propiedad';
}
