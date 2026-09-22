namespace BeDynamic.PropertyManagement;

page 82506 "BeDyn Property Contract List"
{
    PageType = List;
    SourceTable = "BeDyn Property Contract";
    Caption = 'Contratos de propiedad';
    CardPageId = "BeDyn Property Contract Card";
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
                    ToolTip = 'Número del contrato.';
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Explotación (el propietario actúa como proveedor) o Gestión (el propietario actúa como cliente).';
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
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad objeto del contrato.';
                }
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
                    ToolTip = 'Importe mensual pactado con el propietario.';
                }
            }
        }
    }
}
