namespace BeDynamic.PropertyManagement;

table 82509 "BeDyn Portal"
{
    Caption = 'Portal';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Portal List";
    DrillDownPageId = "BeDyn Portal List";

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
        PropertyPortalLink: Record "BeDyn Property Portal Link";
    begin
        PropertyPortalLink.SetRange("Portal Code", "Code");
        if not PropertyPortalLink.IsEmpty() then
            Error(InUseErr, "Code");
    end;

    var
        InUseErr: Label 'No se puede eliminar el portal %1 porque hay propiedades publicadas en él.', Comment = '%1 = Código portal';
}
