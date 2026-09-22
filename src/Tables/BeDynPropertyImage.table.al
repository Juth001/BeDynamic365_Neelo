namespace BeDynamic.PropertyManagement;

table 82519 "BeDyn Property Image"
{
    Caption = 'Imagen de propiedad';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Property No."; Code[20])
        {
            Caption = 'Nº propiedad';
            TableRelation = "BeDyn Property";
            NotBlank = true;
        }
        field(2; "Room No."; Code[20])
        {
            Caption = 'Nº subpropiedad';
            TableRelation = "BeDyn Property Room"."Room No." where("Property No." = field("Property No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        field(4; Image; Media)
        {
            Caption = 'Imagen';
        }
        field(5; "File Name"; Text[250])
        {
            Caption = 'Nombre de archivo';
        }
        field(6; "Source Id"; Text[250])
        {
            Caption = 'Id de origen';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Property No.", "Room No.", "Line No.")
        {
            Clustered = true;
        }
        key(SourceId; "Property No.", "Source Id")
        {
        }
    }

    fieldgroups
    {
        // El fieldgroup Brick permite ver la lista de imágenes en modo iconos/mosaico
        // (como la lista de productos), mostrando la miniatura de cada imagen.
        fieldgroup(Brick; "Room No.", "File Name", Image)
        {
        }
        fieldgroup(DropDown; "Property No.", "Room No.", "File Name")
        {
        }
    }
}
