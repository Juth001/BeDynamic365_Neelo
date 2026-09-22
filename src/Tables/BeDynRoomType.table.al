namespace BeDynamic.PropertyManagement;

table 82514 "BeDyn Room Type"
{
    Caption = 'Tipo subpropiedad';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Room Types";
    DrillDownPageId = "BeDyn Room Types";

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
        field(3; "Property Type Code"; Code[20])
        {
            Caption = 'Cód. tipo propiedad';
            TableRelation = "BeDyn Property Type";
            ToolTip = 'Tipo de propiedad al que pertenece este tipo de subpropiedad. Solo se puede asignar a subpropiedades de propiedades de ese tipo; en blanco, vale para cualquier propiedad.';

            trigger OnValidate()
            var
                PropertyRoom: Record "BeDyn Property Room";
                InUseChangeErr: Label 'No se puede cambiar el tipo de propiedad del tipo de subpropiedad %1 porque hay subpropiedades que lo utilizan.', Comment = '%1 = código tipo subpropiedad';
            begin
                if "Property Type Code" = xRec."Property Type Code" then
                    exit;
                PropertyRoom.SetRange("Room Type Code", "Code");
                if not PropertyRoom.IsEmpty() then
                    Error(InUseChangeErr, "Code");
            end;
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
        PropertyRoom: Record "BeDyn Property Room";
    begin
        PropertyRoom.SetRange("Room Type Code", "Code");
        if not PropertyRoom.IsEmpty() then
            Error(InUseErr, "Code");
    end;

    var
        InUseErr: Label 'No se puede eliminar el tipo de subpropiedad %1 porque hay subpropiedades que lo utilizan.', Comment = '%1 = Código tipo subpropiedad';
}
