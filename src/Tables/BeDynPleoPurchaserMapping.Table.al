namespace BeDynamic.PleoImport;

using Microsoft.CRM.Team;

table 82104 "BeDyn Pleo Purchaser Mapping"
{
    Caption = 'Mapeo Compradores Pleo';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Pleo Purchaser Mapping";
    DrillDownPageId = "BeDyn Pleo Purchaser Mapping";

    fields
    {
        field(1; "Pleo Owner"; Text[100])
        {
            Caption = 'Empleado en Pleo';
            NotBlank = true;
            ToolTip = 'Nombre del empleado tal y como viene en la columna "Owner" del CSV de Pleo.';
        }
        field(2; "Salesperson/Purch. Code"; Code[20])
        {
            Caption = 'Comprador/Vendedor BC';
            TableRelation = "Salesperson/Purchaser";
            ToolTip = 'Comprador/vendedor de Business Central que se asigna como comprador en las facturas de este empleado. Si se deja vacío, la factura se crea sin comprador.';
        }
        field(3; "Non-Deductible"; Boolean)
        {
            Caption = 'No deducible';
            ToolTip = 'Si está activo, los gastos de este empleado SIN justificante (sin URL de recibo) se contabilizan como gasto extraordinario: directamente del banco Pleo a la cuenta de gastos extraordinarios de la configuración, sin IVA ni factura de proveedor. Los gastos CON justificante se tratan de forma normal.';
        }
    }

    keys
    {
        key(PK; "Pleo Owner")
        {
            Clustered = true;
        }
    }
}
