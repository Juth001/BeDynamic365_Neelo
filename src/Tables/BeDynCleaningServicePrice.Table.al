namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using Microsoft.Purchases.Vendor;

table 82702 "BeDyn Cleaning Service Price"
{
    Caption = 'Precio servicio por propiedad';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Cleaning Service Prices";
    DrillDownPageId = "BeDyn Cleaning Service Prices";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Proveedor';
            TableRelation = Vendor."No.";
            NotBlank = true;
            ToolTip = 'Proveedor del servicio.';
        }
        field(2; "Service Code"; Code[20])
        {
            Caption = 'Servicio';
            TableRelation = "BeDyn Cleaning Service".Code where("Vendor No." = field("Vendor No."));
            NotBlank = true;
            ToolTip = 'Servicio del catálogo del proveedor al que aplica el precio.';
        }
        field(3; "Property Code"; Code[20])
        {
            Caption = 'Propiedad';
            TableRelation = "BeDyn Property"."No.";
            NotBlank = true;
            ToolTip = 'Propiedad con precio negociado distinto del precio pactado general del servicio.';
        }
        field(10; Price; Decimal)
        {
            Caption = 'Precio';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            ToolTip = 'Precio unitario negociado para esta propiedad. Sustituye al precio pactado general en la validación de los importes del fichero.';
        }
    }

    keys
    {
        key(PK; "Vendor No.", "Service Code", "Property Code")
        {
            Clustered = true;
        }
    }
}
