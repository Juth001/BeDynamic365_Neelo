namespace BeDynamic.PropertyManagement;

page 82508 "BeDyn Tenant List"
{
    PageType = List;
    SourceTable = "BeDyn Tenant";
    Caption = 'Inquilinos';
    CardPageId = "BeDyn Tenant Card";
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
                    ToolTip = 'Número del inquilino.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del inquilino.';
                }
                field("ID No."; Rec."ID No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Documento de identidad (DNI/NIE).';
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
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cliente vinculado para facturar al inquilino.';
                }
            }
        }
    }
}
