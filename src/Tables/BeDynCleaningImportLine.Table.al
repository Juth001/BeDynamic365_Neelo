namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

table 82700 "BeDyn Cleaning Import Line"
{
    Caption = 'Línea importación limpiezas';
    DataClassification = CustomerContent;
    DrillDownPageId = "BeDyn Cleaning Import Wksh.";
    LookupPageId = "BeDyn Cleaning Import Wksh.";

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
            ToolTip = 'Número de fila en el fichero CSV original del proveedor.';
        }

        // ---------------- DATOS DEL CSV ----------------
        field(10; "Service Date"; Date)
        {
            Caption = 'Fecha servicio';
            ToolTip = 'Fecha en la que el proveedor prestó el servicio.';

            trigger OnValidate()
            begin
                ResetToPending();
            end;
        }
        field(11; "Property Code"; Code[20])
        {
            Caption = 'Cód. propiedad';
            TableRelation = "BeDyn Property"."No.";
            ValidateTableRelation = false;
            ToolTip = 'Código de la propiedad según la columna añadida al CSV. Determina el proyecto al que se imputa el gasto. Se puede corregir a mano y volver a validar.';

            trigger OnValidate()
            begin
                ResetToPending();
            end;
        }
        field(12; "Property Name (CSV)"; Text[100])
        {
            Caption = 'Propiedad (CSV)';
            ToolTip = 'Nombre de la propiedad tal y como aparece en el fichero del proveedor (informativo).';
        }
        field(13; Category; Text[50])
        {
            Caption = 'Categoría (CSV)';
            ToolTip = 'Categoría del servicio según el proveedor: Habitaciones, Apartamento, Erasmus, Oficina, Externo... (informativa).';
        }
        field(14; Tenant; Text[100])
        {
            Caption = 'Inquilino/Cliente (CSV)';
            ToolTip = 'Inquilino o cliente externo indicado por el proveedor (informativo).';
        }
        field(15; "Service Code"; Code[20])
        {
            Caption = 'Servicio';
            TableRelation = "BeDyn Cleaning Service".Code where("Vendor No." = field("Vendor No."));
            ToolTip = 'Servicio del catálogo del proveedor: determina la cuenta de gasto, la tarea del proyecto y el precio pactado.';

            trigger OnValidate()
            begin
                ResetToPending();
            end;
        }
        field(16; Quantity; Decimal)
        {
            Caption = 'Cantidad';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Cantidad del servicio: horas de limpieza, kilos de ropa o número de kits.';

            trigger OnValidate()
            begin
                ResetToPending();
            end;
        }
        field(17; Amount; Decimal)
        {
            Caption = 'Importe (base)';
            AutoFormatType = 1;
            ToolTip = 'Coste del servicio sin IVA según el fichero del proveedor. Es el importe que se reclasifica.';

            trigger OnValidate()
            begin
                ResetToPending();
            end;
        }
        field(18; Comment; Text[250])
        {
            Caption = 'Comentario (CSV)';
            ToolTip = 'Comentario del proveedor sobre el servicio (limpieza profunda, viaje perdido...).';
        }
        field(19; "Review Flag"; Boolean)
        {
            Caption = 'Revisar (proveedor)';
            ToolTip = 'La fila venía marcada por el proveedor para revisión (TO REVIEW). No bloquea el proceso, pero conviene revisarla.';
        }
        field(20; "Allow Deviation"; Boolean)
        {
            Caption = 'Admitir desviación precio';
            ToolTip = 'Acepta la desviación de precio de la línea: al revalidar desaparece el aviso de importe que no cuadra con cantidad × precio pactado (p. ej. tarifas dobles nocturnas).';

            trigger OnValidate()
            begin
                ResetToPending();
            end;
        }
        field(21; "Vendor No."; Code[20])
        {
            Caption = 'Proveedor';
            TableRelation = Vendor."No.";
            ToolTip = 'Proveedor del servicio: el de la columna proveedor del fichero o, si viene vacía, el elegido al importar. La factura asignada debe ser suya. Se puede corregir a mano y volver a validar.';

            trigger OnValidate()
            begin
                ResetToPending();
            end;
        }
        field(22; "Service Description"; Text[100])
        {
            Caption = 'Descripción servicio';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Cleaning Service".Description where("Vendor No." = field("Vendor No."), Code = field("Service Code")));
            Editable = false;
            ToolTip = 'Descripción del servicio en el catálogo del proveedor.';
        }

        // ---------------- RESOLUCIÓN ----------------
        field(30; "Job No."; Code[20])
        {
            Caption = 'Proyecto';
            TableRelation = Job."No.";
            ToolTip = 'Proyecto de la propiedad al que se imputará el gasto. Se resuelve en la validación desde la ficha de propiedad.';
        }
        field(31; "Job Task No."; Code[20])
        {
            Caption = 'Tarea proyecto';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            ToolTip = 'Tarea estándar del proyecto a la que se imputará el gasto, según el servicio (configuración de gestión de propiedades).';
        }
        field(32; "Expected Unit Price"; Decimal)
        {
            Caption = 'Precio pactado';
            DecimalPlaces = 2 : 5;
            ToolTip = 'Precio unitario acordado con el proveedor para este servicio, según la configuración. Contra él se valida el importe de la línea.';
        }
        field(33; "G/L Account No."; Code[20])
        {
            Caption = 'Cuenta de gasto';
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting));
            ToolTip = 'Cuenta de gasto real donde la reclasificación cargará el servicio, según la configuración.';
        }

        // ---------------- FACTURA / ESTADO ----------------
        field(40; "Invoice No."; Code[20])
        {
            Caption = 'Nº factura registrada';
            TableRelation = "Purch. Inv. Header"."No." where("Buy-from Vendor No." = field("Vendor No."), "BeDyn Dimensioned" = const(false));
            ValidateTableRelation = false;
            ToolTip = 'Factura de compra registrada del proveedor en la que viene facturado este servicio: la de la columna factura del fichero o la asignada en la hoja. La reclasificación exige que la suma de las líneas asignadas cuadre con la base imponible de la factura.';

            trigger OnValidate()
            var
                PurchInvHeader: Record "Purch. Inv. Header";
                AlreadyPostedErr: Label 'La línea ya está reclasificada: no se puede cambiar la factura.';
                NotFoundErr: Label 'La factura registrada %1 no existe.', Comment = '%1 = nº factura';
                WrongVendorErr: Label 'La factura %1 no es del proveedor %2 de la línea.', Comment = '%1 = nº factura, %2 = proveedor';
            begin
                if Status = Status::Posted then
                    Error(AlreadyPostedErr);
                if "Invoice No." = '' then
                    exit;
                if not PurchInvHeader.Get("Invoice No.") then
                    Error(NotFoundErr, "Invoice No.");
                if ("Vendor No." <> '') and (PurchInvHeader."Buy-from Vendor No." <> "Vendor No.") then
                    Error(WrongVendorErr, "Invoice No.", "Vendor No.");
            end;
        }
        field(50; Status; Enum "BeDyn Cleaning Line Status")
        {
            Caption = 'Estado';
            InitValue = Pending;
            ToolTip = 'Estado de la línea: pendiente de validar, con error, validada o ya reclasificada.';
        }
        field(51; "Error Message"; Text[250])
        {
            Caption = 'Mensaje';
            ToolTip = 'Motivo del error de validación de la línea.';
        }
        field(52; "Warning Message"; Text[250])
        {
            Caption = 'Aviso';
            ToolTip = 'Aviso no bloqueante detectado en la importación o la validación. La línea se puede procesar igualmente.';
        }
        field(60; "Reclass Document No."; Code[20])
        {
            Caption = 'Documento reclasificación';
            ToolTip = 'Número de documento del diario de reclasificación generado para esta línea (coincide con el número de la factura asignada).';
        }
        field(61; "Reclass Posting Date"; Date)
        {
            Caption = 'Fecha reclasificación';
            ToolTip = 'Fecha de registro del diario de reclasificación generado para esta línea.';
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
        key(Invoice; "Invoice No.", Status)
        {
            SumIndexFields = Amount;
        }
        key(Grouping; "Invoice No.", "Job No.", "Service Code", "Service Date")
        {
        }
    }

    trigger OnDelete()
    var
        PostedDeleteErr: Label 'La línea %1 ya está reclasificada (documento %2): no se puede eliminar.', Comment = '%1 = nº movimiento, %2 = documento';
    begin
        if Status = Status::Posted then
            Error(PostedDeleteErr, "Entry No.", "Reclass Document No.");
    end;

    procedure SetErrorState(ErrText: Text)
    begin
        Rec.Status := Rec.Status::Error;
        Rec."Error Message" := CopyStr(ErrText, 1, MaxStrLen(Rec."Error Message"));
        Rec.Modify(true);
    end;

    // Una corrección manual invalida la validación anterior: la línea vuelve a
    // Pendiente para obligar a validarla de nuevo antes de reclasificar.
    local procedure ResetToPending()
    var
        AlreadyPostedErr: Label 'La línea ya está reclasificada: no se puede modificar.';
    begin
        if Status = Status::Posted then
            Error(AlreadyPostedErr);
        Status := Status::Pending;
        "Error Message" := '';
    end;
}
