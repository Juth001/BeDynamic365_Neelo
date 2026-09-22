namespace BeDynamic.PropertyManagement;

table 82515 "BeDyn Stay Type"
{
    Caption = 'Tipo estancia';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Stay Types";
    DrillDownPageId = "BeDyn Stay Types";

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

}
