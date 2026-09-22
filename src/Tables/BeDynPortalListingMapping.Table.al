namespace BeDynamic.PortalImport;

using BeDynamic.PropertyManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;

table 82602 "BeDyn Portal Listing Mapping"
{
    Caption = 'Mapeo Alojamientos Portales';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Portal Listing Mapping";
    DrillDownPageId = "BeDyn Portal Listing Mapping";

    fields
    {
        field(1; "Portal Code"; Code[20])
        {
            Caption = 'Portal';
            NotBlank = true;
            TableRelation = "BeDyn Portal".Code;
            ToolTip = 'Portal de venta al que pertenece el alojamiento (del maestro de Portales). El portal determina el canal de importación mediante su campo "Canal de importación".';
        }
        field(2; "Listing Key"; Text[100])
        {
            Caption = 'Clave alojamiento';
            NotBlank = true;
            ToolTip = 'Identificador del alojamiento en el CSV del portal: el nombre exacto en Airbnb, el ID numérico en Booking.';
        }
        field(3; "Portal Description"; Text[100])
        {
            Caption = 'Descripción portal';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Portal".Description where(Code = field("Portal Code")));
            Editable = false;
            ToolTip = 'Descripción del portal en el maestro de Portales.';
        }
        field(10; "Listing Name"; Text[100])
        {
            Caption = 'Alojamiento';
            ToolTip = 'Nombre del alojamiento en el portal (informativo; en Booking se rellena automáticamente al importar).';
        }
        field(11; "Property Code"; Code[20])
        {
            Caption = 'Cód. propiedad';
            TableRelation = Item."No.";
            ToolTip = 'Producto que representa la propiedad del alojamiento (código de producto = código de propiedad = valor de dimensión, la misma propiedad que usa la importación de Pleo).';

            trigger OnValidate()
            var
                Setup: Record "BeDyn Portal Setup";
                DimValue: Record "Dimension Value";
                Item: Record Item;
                NoDimValueErr: Label 'El valor %1 no existe en la dimensión %2. Elige un valor existente con el lookup o activa "Auto-crear valores de dimensión" en la configuración para que se cree al contabilizar.', Comment = '%1 = código propiedad, %2 = dimensión';
            begin
                // La variante depende del producto: al cambiarlo, se limpia.
                if Rec."Property Code" <> xRec."Property Code" then
                    Rec."Variant Code" := '';
                if Rec."Property Code" = '' then
                    exit;
                Setup.GetSetup();
                if Setup."Property Dimension Code" <> '' then
                    if DimValue.Get(Setup."Property Dimension Code", Rec."Property Code") then begin
                        // Aprovechar el nombre del valor de dimensión si aún no hay nombre.
                        if Rec."Property Name" = '' then
                            Rec."Property Name" := CopyStr(DimValue.Name, 1, MaxStrLen(Rec."Property Name"));
                    end else
                        if not Setup."Auto Create Dim. Values" then
                            Error(NoDimValueErr, Rec."Property Code", Setup."Property Dimension Code");
                if (Rec."Property Name" = '') and Item.Get(Rec."Property Code") then
                    Rec."Property Name" := CopyStr(Item.Description, 1, MaxStrLen(Rec."Property Name"));
            end;
        }
        field(12; "Property Name"; Text[100])
        {
            Caption = 'Nombre propiedad';
            ToolTip = 'Nombre descriptivo de la propiedad (informativo; se usa al auto-crear el valor de dimensión).';
        }
        field(13; "Variant Code"; Code[10])
        {
            Caption = 'Cód. variante';
            TableRelation = "Item Variant".Code where("Item No." = field("Property Code"));
            ToolTip = 'Variante del producto de la propiedad con la que se facturan las reservas de este alojamiento (p.ej. la habitación H1 en alquiler por subpropiedades). Vacía, se usa la variante por defecto de la configuración. Requiere haber indicado antes el código de propiedad.';

            trigger OnValidate()
            begin
                if Rec."Variant Code" <> '' then
                    Rec.TestField("Property Code");
            end;
        }
    }

    keys
    {
        key(PK; "Portal Code", "Listing Key")
        {
            Clustered = true;
        }
    }

    /// <summary>Busca el mapeo del alojamiento por canal de importación, resolviendo el portal del canal.</summary>
    procedure GetByChannel(Channel: Enum "BeDyn Portal Channel"; ListingKey: Text[100]): Boolean
    var
        ChannelMgt: Codeunit "BeDyn Portal Channel Mgt.";
        PortalCode: Code[20];
    begin
        PortalCode := ChannelMgt.FindPortalCode(Channel);
        if PortalCode = '' then
            exit(false);
        exit(Rec.Get(PortalCode, ListingKey));
    end;
}
