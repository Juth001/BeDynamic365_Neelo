namespace BeDynamic.PropertyManagement;

page 82502 "BeDyn Property Owner Card"
{
    PageType = Card;
    SourceTable = "BeDyn Property Owner";
    Caption = 'Ficha propietario';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número del propietario.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del propietario.';
                }
                field("No. of Properties"; Rec."No. of Properties")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de propiedades del propietario.';
                }
            }
            group(Communication)
            {
                Caption = 'Comunicación';

                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    ToolTip = 'Dirección del propietario.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Población del propietario.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código postal.';
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
            }
            group(Invoicing)
            {
                Caption = 'Facturación';

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Proveedor vinculado. Necesario para contratos de explotación (el propietario nos factura).';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cliente vinculado. Necesario para contratos de gestión (le facturamos el fee de gestión).';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Properties)
            {
                ApplicationArea = All;
                Caption = 'Propiedades';
                Image = Home;
                RunObject = page "BeDyn Property List";
                RunPageLink = "Owner No." = field("No.");
                ToolTip = 'Ver las propiedades de este propietario.';
            }
            action(Contracts)
            {
                ApplicationArea = All;
                Caption = 'Contratos';
                Image = Agreement;
                RunObject = page "BeDyn Property Contract List";
                RunPageLink = "Owner No." = field("No.");
                ToolTip = 'Ver los contratos de este propietario.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Properties_Promoted; Properties)
                {
                }
                actionref(Contracts_Promoted; Contracts)
                {
                }
            }
        }
    }
}
