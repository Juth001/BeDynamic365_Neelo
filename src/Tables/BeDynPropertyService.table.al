namespace BeDynamic.PropertyManagement;

using Microsoft.Finance.Dimension;

table 82506 "BeDyn Property Service"
{
    Caption = 'Servicio';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Property Service List";
    DrillDownPageId = "BeDyn Property Service List";

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
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.DeleteDefaultDim(Database::"BeDyn Property Service", "Code");
    end;

    trigger OnRename()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.RenameDefaultDim(Database::"BeDyn Property Service", xRec."Code", "Code");
    end;
}
