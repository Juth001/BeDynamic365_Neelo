namespace BeDynamic.PropertyManagement;

page 82509 "BeDyn Tenant Card"
{
    PageType = Card;
    SourceTable = "BeDyn Tenant";
    Caption = 'Ficha inquilino';

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
                    ToolTip = 'Número del inquilino.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
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
                field("Customer Type"; Rec."Customer Type")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cliente vinculado para facturar al inquilino (contratos de explotación).';
                }
            }
            group(Communication)
            {
                Caption = 'Comunicación';

                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    ToolTip = 'Dirección del inquilino.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Población del inquilino.';
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
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Reservations)
            {
                ApplicationArea = All;
                Caption = 'Reservas';
                Image = Reserve;
                RunObject = page "BeDyn Reservation List";
                RunPageLink = "Tenant No." = field("No.");
                ToolTip = 'Ver las reservas de este inquilino.';
            }
            action(Deposits)
            {
                ApplicationArea = All;
                Caption = 'Fianzas';
                Image = Balance;
                RunObject = page "BeDyn Deposit List";
                RunPageLink = "Tenant No." = field("No.");
                ToolTip = 'Ver las fianzas pagadas por este inquilino.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Reservations_Promoted; Reservations)
                {
                }
                actionref(Deposits_Promoted; Deposits)
                {
                }
            }
        }
    }
}
