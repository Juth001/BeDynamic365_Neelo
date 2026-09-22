namespace BeDynamic.PropertyManagement;

table 82510 "BeDyn Property Portal Link"
{
    Caption = 'Publicación en portal';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Property No."; Code[20])
        {
            Caption = 'Nº propiedad';
            TableRelation = "BeDyn Property";
            NotBlank = true;
        }
        field(2; "Portal Code"; Code[20])
        {
            Caption = 'Cód. portal';
            TableRelation = "BeDyn Portal";
            NotBlank = true;
        }
        field(3; URL; Text[2048])
        {
            Caption = 'URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            begin
                if (URL <> '') and (not URL.ToLower().StartsWith('http://')) and (not URL.ToLower().StartsWith('https://')) then
                    URL := CopyStr('https://' + URL, 1, MaxStrLen(URL));
            end;
        }
        field(4; "Portal Description"; Text[100])
        {
            Caption = 'Descripción portal';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Portal".Description where("Code" = field("Portal Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Property No.", "Portal Code")
        {
            Clustered = true;
        }
    }
}
