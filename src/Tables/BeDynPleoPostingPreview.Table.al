namespace BeDynamic.PleoImport;

table 82106 "BeDyn Pleo Posting Preview"
{
    Caption = 'Vista previa registro Pleo';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº';
            ToolTip = 'Número de línea de la vista previa.';
        }
        field(2; "Buffer Entry No."; Integer)
        {
            Caption = 'Nº movimiento';
            ToolTip = 'Número de la línea correspondiente en la hoja de importación.';
        }
        field(3; "Receipt No."; Code[20])
        {
            Caption = 'Nº recibo Pleo';
            ToolTip = 'Número de recibo del gasto en Pleo.';
        }
        field(10; Operation; Text[50])
        {
            Caption = 'Operación';
            ToolTip = 'Tipo de documento o diario que se generará al registrar.';
        }
        field(11; "Posting Date"; Date)
        {
            Caption = 'Fecha registro';
            ToolTip = 'Fecha con la que se registrará el documento o diario.';
        }
        field(12; "Vendor No."; Code[20])
        {
            Caption = 'Proveedor';
            ToolTip = 'Proveedor de la factura o abono de compra.';
        }
        field(13; "Vendor Name"; Text[100])
        {
            Caption = 'Nombre proveedor';
            ToolTip = 'Nombre del proveedor de la factura o abono de compra.';
        }
        field(14; "Account Kind"; Text[20])
        {
            Caption = 'Tipo línea';
            ToolTip = 'Tipo de la línea del documento: cuenta contable, activo fijo o banco.';
        }
        field(15; "Account No."; Code[20])
        {
            Caption = 'Cuenta/Activo';
            ToolTip = 'Cuenta contable, activo fijo o banco de la línea (la contrapartida en los diarios contra el banco Pleo).';
        }
        field(16; Description; Text[100])
        {
            Caption = 'Descripción';
            ToolTip = 'Descripción con la que se creará la línea.';
        }
        field(17; Amount; Decimal)
        {
            Caption = 'Importe (IVA incl.)';
            AutoFormatType = 1;
            ToolTip = 'Importe del documento o diario, en positivo (la operación indica el sentido).';
        }
        field(18; "External Doc. No."; Code[35])
        {
            Caption = 'Nº doc. externo';
            ToolTip = 'Nº de factura de proveedor / documento externo (prefijo + nº de recibo Pleo).';
        }
        field(19; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Grupo IVA prod.';
            ToolTip = 'Grupo de IVA producto que se forzará en la línea del documento de compra.';
        }
        field(20; "Project Code"; Code[20])
        {
            Caption = 'Propiedad';
            ToolTip = 'Valor de la dimensión de proyecto/propiedad que llevará el documento.';
        }
        field(24; "Job Task No."; Code[20])
        {
            Caption = 'Tarea proyecto';
            ToolTip = 'Tarea del proyecto de la propiedad a la que se imputará el gasto.';
        }
        field(21; "Purchaser Code"; Code[20])
        {
            Caption = 'Comprador';
            ToolTip = 'Comprador que se asignará al documento.';
        }
        field(22; "Action Text"; Text[80])
        {
            Caption = 'Acción';
            ToolTip = 'Qué se hará con el documento según la configuración: solo borrador, registrar, o registrar y pagar contra el banco Pleo.';
        }
        field(23; Warning; Text[250])
        {
            Caption = 'Aviso';
            ToolTip = 'Aviso no bloqueante de la línea (p.ej. falta el justificante).';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
