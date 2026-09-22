namespace BeDynamic.PropertyManagement;

table 82802 "BeDyn Guest Type"
{
    // Tipo de huésped de una reserva concreta (simple, colaborador…), distinto del
    // tipo de cliente, que va en la ficha del inquilino.

    Caption = 'Tipo de huésped';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Guest Types";
    DrillDownPageId = "BeDyn Guest Types";

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
