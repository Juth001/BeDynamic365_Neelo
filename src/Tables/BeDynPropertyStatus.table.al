namespace BeDynamic.PropertyManagement;

table 82511 "BeDyn Property Status"
{
    Caption = 'Estado propiedad';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Property Statuses";
    DrillDownPageId = "BeDyn Property Statuses";

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
    begin
        Property.SetRange("Status Code", "Code");
        if not Property.IsEmpty() then
            Error(InUseErr, "Code");
    end;

    var
        InUseErr: Label 'No se puede eliminar el estado %1 porque hay propiedades que lo utilizan.', Comment = '%1 = Código estado';
}
