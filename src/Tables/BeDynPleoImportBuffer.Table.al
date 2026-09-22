namespace BeDynamic.PleoImport;

using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;

table 82101 "BeDyn Pleo Import Buffer"
{
    Caption = 'Buffer Importación Pleo';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº movimiento';
            AutoIncrement = true;
            ToolTip = 'Número interno de la línea en la hoja de importación.';
        }
        field(2; "Batch Code"; Code[20])
        {
            Caption = 'Lote';
            ToolTip = 'Identificador del lote de importación, para procesar y filtrar por tandas.';
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
            ToolTip = 'Fecha del gasto en Pleo. Se usa como fecha de documento y de registro.';
        }
        field(11; "Receipt No."; Code[20])
        {
            Caption = 'Nº recibo Pleo';
            ToolTip = 'Número de recibo del gasto en Pleo. Con el prefijo del setup forma el nº de factura de proveedor.';
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
            ToolTip = 'Divisa del gasto (solo se soporta EUR).';
        }
        field(15; "Source Description"; Text[100])
        {
            Caption = 'Comercio';
            ToolTip = 'Comercio donde se realizó el gasto. Forma parte de la descripción de la línea contable.';
        }
        field(16; Category; Text[100])
        {
            Caption = 'Categoría Pleo';
            ToolTip = 'Categoría del gasto en Pleo (informativa).';
        }
        field(17; Owner; Text[100])
        {
            Caption = 'Empleado';
            ToolTip = 'Empleado que realizó el gasto en Pleo. Determina el comprador mediante el mapeo de compradores.';
        }
        field(18; Note; Text[250])
        {
            Caption = 'Nota';
            ToolTip = 'Nota introducida por el empleado en Pleo. Forma parte de la descripción de la línea contable.';
        }
        field(19; Team; Text[50])
        {
            Caption = 'Equipo';
            ToolTip = 'Equipo del empleado en Pleo (informativo).';
        }
        field(20; "Expense ID"; Text[50])
        {
            Caption = 'Id. gasto Pleo';
            ToolTip = 'Identificador único del gasto en Pleo. Se usa para no importar dos veces el mismo movimiento.';
        }
        field(21; "Receipt URL"; Text[250])
        {
            Caption = 'URL recibo';
            ToolTip = 'Enlace al justificante del gasto en Pleo. Si está vacío, la línea se marca con el aviso de falta de justificante.';
        }
        field(30; "Project Code"; Code[20])
        {
            Caption = 'Cód. proyecto (Pleo)';
            ToolTip = 'Código del proyecto (propiedad) de Pleo. Determina la dimensión de proyecto y la ubicación del activo fijo en CAPEX.';
        }
        field(31; "Project Name"; Text[100])
        {
            Caption = 'Proyecto (Pleo)';
            ToolTip = 'Nombre del proyecto (propiedad) de Pleo.';
        }
        field(32; "Cost Type Code"; Code[20])
        {
            Caption = 'Cód. tipo gasto (Pleo)';
            ToolTip = 'Código del tipo de gasto de Pleo. Determina la cuenta o el tratamiento CAPEX mediante el mapeo de tipos de gasto.';
        }
        field(33; "Cost Type Name"; Text[100])
        {
            Caption = 'Tipo gasto (Pleo)';
            ToolTip = 'Nombre del tipo de gasto de Pleo.';
        }
        field(34; "Pleo Vendor Code"; Code[20])
        {
            Caption = 'Cód. proveedor (Pleo)';
            ToolTip = 'Código de proveedor de Pleo. Determina el proveedor BC mediante el mapeo de proveedores.';
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
            ToolTip = 'Proveedor de Business Central con el que se creará la factura. Se puede corregir a mano antes de procesar.';
        }
        field(41; "G/L Account No."; Code[20])
        {
            Caption = 'Cuenta de gasto';
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting));
            ToolTip = 'Cuenta de gasto de la línea. Se puede corregir a mano antes de procesar.';
        }
        field(42; CAPEX; Boolean)
        {
            Caption = 'CAPEX';
            ToolTip = 'Indica que el tipo de gasto está marcado como CAPEX: la línea se contabiliza como adquisición de activo fijo en vez de gasto.';
        }
        field(43; "Fixed Asset No."; Code[20])
        {
            Caption = 'Activo fijo';
            TableRelation = "Fixed Asset"."No.";
            ToolTip = 'Activo fijo al que se carga la adquisición (resuelto por la ubicación = propiedad). Se puede corregir a mano antes de procesar.';
        }
        field(44; "Purchaser Code"; Code[20])
        {
            Caption = 'Comprador';
            TableRelation = "Salesperson/Purchaser";
            ToolTip = 'Comprador asignado a la factura, resuelto por el mapeo de compradores a partir del empleado de Pleo. Se puede corregir a mano antes de procesar.';
        }
        field(46; "Job No."; Code[20])
        {
            Caption = 'Proyecto BC';
            TableRelation = Job."No.";
            ToolTip = 'Proyecto de BC (mismo código que la propiedad) al que se imputará el gasto. Se resuelve en la validación y se puede corregir a mano antes de procesar.';
        }
        field(47; "Job Task No."; Code[20])
        {
            Caption = 'Tarea proyecto';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            ToolTip = 'Tarea del proyecto a la que se imputará el gasto, según el mapeo del tipo de gasto. Se puede corregir a mano antes de procesar.';
        }
        field(45; Extraordinary; Boolean)
        {
            Caption = 'Gasto extraordinario';
            ToolTip = 'Empleado marcado como no deducible y gasto sin justificante: se registra con un diario directo del banco Pleo a la cuenta de gastos extraordinarios, sin IVA ni factura de proveedor.';
        }

        // ---------------- ESTADO / RESULTADO ----------------
        field(50; Status; Enum "BeDyn Pleo Line Status")
        {
            Caption = 'Estado';
            InitValue = Pending;
            ToolTip = 'Estado de la línea en el flujo de importación.';
        }
        field(51; "Error Message"; Text[250])
        {
            Caption = 'Mensaje';
            ToolTip = 'Motivo del error o de la omisión de la línea.';
        }
        field(52; "Warning Message"; Text[250])
        {
            Caption = 'Aviso';
            ToolTip = 'Aviso no bloqueante detectado en la validación (p.ej. falta el justificante). La línea se puede procesar igualmente.';
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
            ToolTip = 'Indica que el pago contra el banco Pleo ya se ha registrado.';
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
    }

    procedure SetErrorState(ErrText: Text)
    begin
        Rec.Status := Rec.Status::Error;
        Rec."Error Message" := CopyStr(ErrText, 1, MaxStrLen(Rec."Error Message"));
        Rec.Modify(true);
    end;

    procedure SetSkippedState(ReasonText: Text)
    begin
        Rec.Status := Rec.Status::Skipped;
        Rec."Error Message" := CopyStr(ReasonText, 1, MaxStrLen(Rec."Error Message"));
        Rec.Modify(true);
    end;
}
