namespace BeDynamic.PleoImport;

using Microsoft.Purchases.Vendor;

table 82102 "BeDyn Pleo Vendor Mapping"
{
    Caption = 'Mapeo Proveedores Pleo';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Pleo Vendor Mapping";
    DrillDownPageId = "BeDyn Pleo Vendor Mapping";

    fields
    {
        field(1; "Pleo Code"; Code[20])
        {
            Caption = 'Cód. proveedor Pleo';
            NotBlank = true;
            ToolTip = 'Código de la columna "Proveedor - Code" del CSV de Pleo (p.ej. 1 = Leroy Merlín, 10 = Obramat).';
        }
        field(2; "Pleo Name"; Text[100])
        {
            Caption = 'Nombre en Pleo';
            ToolTip = 'Nombre del proveedor tal y como aparece en Pleo (informativo).';
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Proveedor BC';
            TableRelation = Vendor."No.";
            ToolTip = 'Proveedor de Business Central al que se asignan las facturas de este código Pleo. Si se deja vacío, se usa el proveedor genérico del setup.';
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
