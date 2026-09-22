namespace BeDynamic.PleoImport;

using BeDynamic.PropertyWizard;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.Setup;

table 82103 "BeDyn Pleo Expense Type Map"
{
    Caption = 'Mapeo Tipos de Gasto Pleo';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Pleo Expense Type Map";
    DrillDownPageId = "BeDyn Pleo Expense Type Map";

    fields
    {
        field(1; "Pleo Code"; Code[20])
        {
            Caption = 'Cód. tipo gasto Pleo';
            NotBlank = true;
            ToolTip = 'Código de la columna "Tipo Gasto - Code" del CSV de Pleo (p.ej. 1 = Mobiliario, 2 = Material Obra, 4 = Mantenimiento).';
        }
        field(2; "Pleo Name"; Text[100])
        {
            Caption = 'Nombre en Pleo';
            ToolTip = 'Nombre del tipo de gasto tal y como aparece en Pleo (informativo).';
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'Cuenta de gasto';
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting));
            ToolTip = 'Cuenta contable donde se contabilizan los gastos de este tipo (solo si no es CAPEX). Si se deja vacía, se usa la cuenta por defecto del setup.';
        }
        field(4; CAPEX; Boolean)
        {
            Caption = 'CAPEX (activo fijo)';
            ToolTip = 'Si está activo, los gastos de este tipo se contabilizan como adquisición de activo fijo. El activo se determina por la propiedad (Proyecto de Pleo = ubicación del activo) y por la clase/subclase indicadas aquí.';

            trigger OnValidate()
            begin
                if not CAPEX then begin
                    "FA Class Code" := '';
                    "FA Subclass Code" := '';
                end;
            end;
        }
        field(7; "Job Task No."; Code[20])
        {
            Caption = 'Tarea de proyecto';
            TableRelation = "BeDyn Property Task Template"."Job Task No.";
            ValidateTableRelation = false;
            ToolTip = 'Tarea del proyecto de la propiedad donde se repercuten los gastos de este tipo (p.ej. 10 Mobiliario). Si la propiedad tiene un proyecto BC con su mismo código, la línea de la factura se imputa a esa tarea. Vacía = sin imputación a proyecto.';
        }
        field(5; "FA Class Code"; Code[10])
        {
            Caption = 'Clase activo fijo';
            TableRelation = "FA Class";
            ToolTip = 'Clase de activo fijo que se aplica al buscar/crear el activo cuando el tipo de gasto es CAPEX. Si se deja vacía, no se distingue por clase.';

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
            begin
                if ("FA Class Code" <> '') and ("FA Subclass Code" <> '') then
                    if FASubclass.Get("FA Subclass Code") then
                        if (FASubclass."FA Class Code" <> '') and (FASubclass."FA Class Code" <> "FA Class Code") then
                            "FA Subclass Code" := '';
            end;
        }
        field(6; "FA Subclass Code"; Code[10])
        {
            Caption = 'Subclase activo fijo';
            TableRelation = if ("FA Class Code" = filter('')) "FA Subclass"
            else
            "FA Subclass" where("FA Class Code" = field("FA Class Code"));
            ToolTip = 'Subclase de activo fijo que se aplica al buscar/crear el activo cuando el tipo de gasto es CAPEX. Si se deja vacía (y tampoco hay clase), se usa la subclase de la configuración.';

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
                SubclassClassErr: Label 'La subclase %1 no pertenece a la clase %2.', Comment = '%1 = subclase, %2 = clase';
            begin
                if "FA Subclass Code" = '' then
                    exit;
                FASubclass.Get("FA Subclass Code");
                if FASubclass."FA Class Code" = '' then
                    exit;
                if "FA Class Code" = '' then
                    "FA Class Code" := FASubclass."FA Class Code"
                else
                    if "FA Class Code" <> FASubclass."FA Class Code" then
                        Error(SubclassClassErr, "FA Subclass Code", "FA Class Code");
            end;
        }
    }

    keys
    {
        key(PK; "Pleo Code")
        {
            Clustered = true;
        }
    }
}
