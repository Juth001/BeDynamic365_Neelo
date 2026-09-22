namespace BeDynamic.PropertyManagement;

page 82507 "BeDyn Property Contract Card"
{
    PageType = Card;
    SourceTable = "BeDyn Property Contract";
    Caption = 'Ficha contrato';

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
                    ToolTip = 'Número del contrato.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Explotación: el propietario nos cede la vivienda y nos factura el importe pactado; nosotros facturamos al inquilino. Gestión: gestionamos la propiedad y facturamos al propietario un fee de gestión.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado del contrato.';
                }
                field("Owner No."; Rec."Owner No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propietario del contrato.';
                }
                field("Owner Name"; Rec."Owner Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del propietario.';
                }
                field("Owner Vendor No."; Rec."Owner Vendor No.")
                {
                    ApplicationArea = All;
                    Visible = IsExploitation;
                    ToolTip = 'Proveedor vinculado al propietario. Necesario en los contratos de explotación: el propietario nos factura el alquiler.';
                }
                field("Owner Customer No."; Rec."Owner Customer No.")
                {
                    ApplicationArea = All;
                    Visible = IsManagement;
                    ToolTip = 'Cliente vinculado al propietario. Necesario en los contratos de gestión: le facturamos el fee de gestión.';
                }
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad objeto del contrato.';
                }
                field("Property Name"; Rec."Property Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de la propiedad.';
                }
            }
            group(Conditions)
            {
                Caption = 'Condiciones';

                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha de inicio del contrato.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha de fin del contrato.';
                }
                field("Agreed Rental Amount"; Rec."Agreed Rental Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Explotación: importe mensual que nos factura el propietario. Gestión: importe de alquiler pactado con el propietario.';
                }
            }
            group(ManagementGroup)
            {
                Caption = 'Gestión';
                Visible = IsManagement;

                field(InvoicedAmount; InvoicedAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Importe facturado (reservas)';
                    Editable = false;
                    ToolTip = 'Total facturado por la propiedad: suma de las reservas no canceladas dentro del periodo del contrato.';
                }
                field(ManagementFee; ManagementFee)
                {
                    ApplicationArea = All;
                    Caption = 'Fee de gestión';
                    Editable = false;
                    ToolTip = 'Diferencia entre lo facturado por la propiedad y el importe de alquiler pactado con el propietario.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsManagement := Rec."Contract Type" = Rec."Contract Type"::Management;
        IsExploitation := Rec."Contract Type" = Rec."Contract Type"::Exploitation;
        InvoicedAmount := Rec.GetInvoicedAmount();
        ManagementFee := Rec.GetManagementFee();
    end;

    // Heredar propietario y propiedad cuando la ficha se abre desde una lista
    // filtrada (acción Contratos del propietario o de la propiedad). Se asigna
    // sin Validate: la comprobación del rol del propietario según el tipo de
    // contrato ya salta al validar el tipo o el propietario a mano.
    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Property: Record "BeDyn Property";
    begin
        if (Rec."Owner No." = '') and (Rec.GetFilter("Owner No.") <> '') then
            Rec."Owner No." := Rec.GetRangeMax("Owner No.");
        if (Rec."Property No." = '') and (Rec.GetFilter("Property No.") <> '') then
            if Property.Get(Rec.GetRangeMax("Property No.")) then begin
                if Rec."Owner No." = '' then
                    Rec."Owner No." := Property."Owner No.";
                if Rec."Owner No." = Property."Owner No." then
                    Rec."Property No." := Property."No.";
            end;
    end;

    var
        InvoicedAmount: Decimal;
        ManagementFee: Decimal;
        IsManagement: Boolean;
        IsExploitation: Boolean;
}
