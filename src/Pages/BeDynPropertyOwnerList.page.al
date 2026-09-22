namespace BeDynamic.PropertyManagement;

page 82501 "BeDyn Property Owner List"
{
    PageType = List;
    SourceTable = "BeDyn Property Owner";
    Caption = 'Propietarios';
    CardPageId = "BeDyn Property Owner Card";
    Editable = false;
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número del propietario.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del propietario.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Población del propietario.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Teléfono de contacto.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = All;
                    ToolTip = 'Correo electrónico de contacto.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Proveedor vinculado (contratos de explotación).';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cliente vinculado (contratos de gestión).';
                }
                field("No. of Properties"; Rec."No. of Properties")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de propiedades del propietario.';
                }
            }
        }
    }
}
