namespace BeDynamic.PropertyManagement;

table 82801 "BeDyn Customer Type"
{
    // Tipo de cliente de la ficha del inquilino (particular, colaborador, empresa…).
    // La reserva lo hereda al asignarle el inquilino.

    Caption = 'Tipo de cliente';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Customer Types";
    DrillDownPageId = "BeDyn Customer Types";

    fields
    {
        field(1; Code; Code[20])
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
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description)
        {
        }
    }
}
