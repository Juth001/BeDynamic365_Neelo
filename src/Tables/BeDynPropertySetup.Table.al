namespace BeDynamic.PropertyWizard;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;

table 82400 "BeDyn Property Setup"
{
    Caption = 'Configuración asistente propiedades';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(10; "Property Type Dimension Code"; Code[20])
        {
            Caption = 'Dimensión tipo de propiedad';
            TableRelation = Dimension.Code;
            InitValue = 'TIPOPROPIEDAD';
            ToolTip = 'Dimensión cuyos valores son los tipos de propiedad. El tipo elegido aporta el tercer segmento del código de propiedad: 01 para el primer valor de la dimensión (por código), 02 para el segundo, etc.';
        }
        field(11; "Property Dimension Code"; Code[20])
        {
            Caption = 'Dimensión propiedad';
            TableRelation = Dimension.Code;
            InitValue = 'PROPIEDAD';
            ToolTip = 'Dimensión donde el asistente crea un valor por propiedad, con el mismo código que el producto y el proyecto, y que asigna a ambos como dimensión por defecto.';
        }
        field(12; "Item Template Code"; Code[20])
        {
            Caption = 'Plantilla de producto';
            TableRelation = "Item Templ.".Code;
            ToolTip = 'Plantilla de producto que el asistente propone por defecto. Antes de crear la propiedad, el asistente pide confirmar o cambiar la plantilla, que aporta tipo, unidad de medida y grupos de registro del producto.';
        }
        field(13; "Job Generic Customer No."; Code[20])
        {
            Caption = 'Cliente genérico proyectos';
            TableRelation = Customer."No.";
            ToolTip = 'Cliente que se asigna a los proyectos de propiedad creados por el asistente.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if Rec.Get() then
            exit;
        Rec.Init();
        Rec.Insert(true);
    end;
}
