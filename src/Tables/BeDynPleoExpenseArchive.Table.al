namespace BeDynamic.PleoImport;

using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;

table 82105 "BeDyn Pleo Expense Archive"
{
    Caption = 'Archivo Gastos Pleo';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Pleo Expense Archive";
    DrillDownPageId = "BeDyn Pleo Expense Archive";

    // Espejo del buffer de importación (mismos nº y tipos de campo, para poder usar
    // TransferFields). Las líneas procesadas se mueven aquí y salen del staging.

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº movimiento';
            ToolTip = 'Número interno que tenía la línea en la hoja de importación.';
        }
        field(2; "Batch Code"; Code[20])
        {
            Caption = 'Lote';
            ToolTip = 'Lote de importación al que pertenecía la línea.';
        }
        field(3; "Row No."; Integer)
        {
            Caption = 'Fila CSV';
            ToolTip = 'Número de fila en el fichero CSV original.';
        }

        // ---------------- DATOS DEL CSV ----------------
        field(10; "Expense Date"; Date)
        {
            Caption = 'Fecha';
            ToolTip = 'Fecha del gasto en Pleo.';
        }
        field(11; "Receipt No."; Code[20])
        {
            Caption = 'Nº recibo Pleo';
            ToolTip = 'Número de recibo del gasto en Pleo.';
        }
        field(12; "Expense Type"; Enum "BeDyn Pleo Expense Type")
        {
            Caption = 'Tipo movimiento';
            ToolTip = 'Tipo de movimiento de Pleo: compra con tarjeta, recarga de monedero o cashback.';
        }
        field(13; Amount; Decimal)
        {
            Caption = 'Importe (IVA incluido)';
            AutoFormatType = 1;
            ToolTip = 'Importe con el signo original de Pleo: negativo = gasto, positivo = devolución/recarga.';
        }
        field(14; "Currency Code"; Code[10])
        {
            Caption = 'Divisa';
            ToolTip = 'Divisa del gasto.';
        }
        field(15; "Source Description"; Text[100])
        {
            Caption = 'Comercio';
            ToolTip = 'Comercio donde se realizó el gasto.';
        }
        field(16; Category; Text[100])
        {
            Caption = 'Categoría Pleo';
            ToolTip = 'Categoría del gasto en Pleo. Determinó la cuenta de gasto, el tratamiento CAPEX y la tarea de proyecto mediante el mapeo de categorías.';
        }
        field(17; Owner; Text[100])
        {
            Caption = 'Empleado';
            ToolTip = 'Empleado que realizó el gasto en Pleo.';
        }
        field(18; Note; Text[250])
        {
            Caption = 'Nota';
            ToolTip = 'Nota introducida por el empleado en Pleo.';
        }
        field(19; Team; Text[50])
        {
            Caption = 'Equipo';
            ToolTip = 'Equipo del empleado en Pleo (informativo).';
        }
        field(20; "Expense ID"; Text[50])
        {
            Caption = 'Id. gasto Pleo';
            ToolTip = 'Identificador único del gasto en Pleo. Se sigue teniendo en cuenta para no reimportar movimientos ya archivados.';
        }
        field(21; "Receipt URL"; Text[250])
        {
            Caption = 'URL recibo';
            ToolTip = 'Enlace al justificante del gasto en Pleo.';
        }
        field(30; "Project Code"; Code[20])
        {
            Caption = 'Cód. proyecto (Pleo)';
            ToolTip = 'Código del proyecto (propiedad) de Pleo.';
        }
        field(31; "Project Name"; Text[100])
        {
            Caption = 'Proyecto (Pleo)';
            ToolTip = 'Nombre del proyecto (propiedad) de Pleo.';
        }
        field(34; "Pleo Vendor Code"; Code[20])
        {
            Caption = 'Cód. proveedor (Pleo)';
            ToolTip = 'Código de proveedor de Pleo.';
        }
        field(35; "Pleo Vendor Name"; Text[100])
        {
            Caption = 'Proveedor (Pleo)';
            ToolTip = 'Nombre del proveedor tal y como aparece en Pleo.';
        }

        // ---------------- RESOLUCIÓN ----------------
        field(40; "Mapped Vendor No."; Code[20])
        {
            Caption = 'Proveedor BC asignado';
            TableRelation = Vendor."No.";
            ToolTip = 'Proveedor de Business Central con el que se creó la factura.';
        }
        field(41; "G/L Account No."; Code[20])
        {
            Caption = 'Cuenta de gasto';
            TableRelation = "G/L Account"."No.";
            ToolTip = 'Cuenta de gasto con la que se contabilizó la línea.';
        }
        field(42; CAPEX; Boolean)
        {
            Caption = 'CAPEX';
            ToolTip = 'La línea se contabilizó como adquisición de activo fijo.';
        }
        field(43; "Fixed Asset No."; Code[20])
        {
            Caption = 'Activo fijo';
            TableRelation = "Fixed Asset"."No.";
            ToolTip = 'Activo fijo al que se cargó la adquisición.';
        }
        field(44; "Purchaser Code"; Code[20])
        {
            Caption = 'Comprador';
            TableRelation = "Salesperson/Purchaser";
            ToolTip = 'Comprador asignado a la factura o al diario.';
        }
        field(45; Extraordinary; Boolean)
        {
            Caption = 'Gasto extraordinario';
            ToolTip = 'La línea se contabilizó como gasto extraordinario: diario directo del banco Pleo a la cuenta de gastos extraordinarios, sin IVA.';
        }
        field(46; "Job No."; Code[20])
        {
            Caption = 'Proyecto BC';
            TableRelation = Job."No.";
            ToolTip = 'Proyecto de BC al que se imputó el gasto.';
        }
        field(47; "Job Task No."; Code[20])
        {
            Caption = 'Tarea proyecto';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            ToolTip = 'Tarea del proyecto a la que se imputó el gasto.';
        }

        // ---------------- ESTADO / RESULTADO ----------------
        field(50; Status; Enum "BeDyn Pleo Line Status")
        {
            Caption = 'Estado';
            ToolTip = 'Estado final de la línea al archivarse.';
        }
        field(51; "Error Message"; Text[250])
        {
            Caption = 'Mensaje';
            ToolTip = 'Último mensaje de la línea antes de archivarse.';
        }
        field(52; "Warning Message"; Text[250])
        {
            Caption = 'Aviso';
            ToolTip = 'Aviso no bloqueante de la línea (p.ej. falta el justificante).';
        }
        field(60; "Created Document No."; Code[20])
        {
            Caption = 'Documento BC creado';
            ToolTip = 'Número del borrador de factura o abono creado en Business Central.';
        }
        field(61; "Posted Document No."; Code[20])
        {
            Caption = 'Documento registrado';
            ToolTip = 'Número del documento registrado en Business Central (o del diario, en recargas, cashbacks y gastos extraordinarios).';
        }
        field(62; "Payment Posted"; Boolean)
        {
            Caption = 'Pago registrado';
            ToolTip = 'Indica que el pago contra el banco Pleo se registró.';
        }

        // ---------------- ARCHIVADO ----------------
        field(100; "Archived Date Time"; DateTime)
        {
            Caption = 'Fecha archivado';
            ToolTip = 'Momento en que la línea se movió al archivo.';
        }
        field(101; "Archived By"; Code[50])
        {
            Caption = 'Archivado por';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Usuario que archivó la línea.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Batch; "Batch Code", Status)
        {
        }
        key(Expense; "Expense ID")
        {
        }
        key(Date; "Expense Date")
        {
        }
    }

    procedure ArchiveFromBuffer(Buffer: Record "BeDyn Pleo Import Buffer")
    begin
        Rec.Init();
        Rec.TransferFields(Buffer);
        Rec."Archived Date Time" := CurrentDateTime();
        Rec."Archived By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Archived By"));
        Rec.Insert();
    end;
}
