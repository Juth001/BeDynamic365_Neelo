namespace BeDynamic.PleoImport;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Purchases.Vendor;

table 82100 "BeDyn Pleo Setup"
{
    Caption = 'Configuración Importación Pleo';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }

        // ---------------- GENERAL ----------------
        field(10; "Pleo Bank Account No."; Code[20])
        {
            Caption = 'Banco Pleo (banco puente)';
            TableRelation = "Bank Account"."No.";
            ToolTip = 'Cuenta bancaria de BC que representa el monedero de Pleo. Los pagos de las facturas importadas se registran contra este banco.';
        }
        field(11; "Post Action"; Enum "BeDyn Pleo Post Action")
        {
            Caption = 'Acción tras importar';
            InitValue = "Post & Pay";
            ToolTip = 'Solo borrador: crea las facturas sin registrar. Registrar: registra las facturas. Registrar y pagar: además registra el pago contra el banco Pleo.';
        }
        field(12; "Vendor Invoice No. Prefix"; Code[10])
        {
            Caption = 'Prefijo nº factura proveedor';
            InitValue = 'PLEO-';
            ToolTip = 'Prefijo que se antepone al nº de recibo de Pleo para formar el "Nº factura proveedor" (p.ej. PLEO-2601217).';
        }
        field(13; "File Encoding"; Option)
        {
            Caption = 'Codificación del fichero';
            OptionMembers = "UTF-8","Windows (ANSI)";
            OptionCaption = 'UTF-8,Windows (ANSI)';
            ToolTip = 'Solo se usa si el fichero no permite detectar la codificación automáticamente (sin BOM). Si los acentos salen mal al importar, prueba a cambiar esta opción.';
        }

        // ---------------- COMPRAS ----------------
        field(20; "Generic Vendor No."; Code[20])
        {
            Caption = 'Proveedor genérico';
            TableRelation = Vendor."No.";
            ToolTip = 'Proveedor usado cuando el código de proveedor de Pleo no está mapeado o viene vacío. El nombre real del comercio se conserva en la descripción de la línea.';
        }
        field(21; "Default G/L Account No."; Code[20])
        {
            Caption = 'Cuenta de gasto por defecto';
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting));
            ToolTip = 'Cuenta contable usada cuando la categoría de Pleo no está mapeada, no tiene cuenta asignada o viene vacía.';
        }
        field(22; "Auto Create Vendor Mapping"; Boolean)
        {
            Caption = 'Auto-crear mapeo de proveedores';
            InitValue = true;
            ToolTip = 'Si está activo, los códigos de proveedor de Pleo desconocidos se dan de alta automáticamente en la tabla de mapeo (sin proveedor BC) para completarlos después.';
        }
        field(23; "Auto Create Expense Map"; Boolean)
        {
            Caption = 'Auto-crear mapeo de categorías';
            InitValue = true;
            ToolTip = 'Si está activo, las categorías de Pleo desconocidas se dan de alta automáticamente en la tabla de mapeo (sin cuenta) para completarlas después.';
        }
        field(25; "Auto Create Purchaser Mapping"; Boolean)
        {
            Caption = 'Auto-crear mapeo de compradores';
            InitValue = true;
            ToolTip = 'Si está activo, los empleados de Pleo desconocidos se dan de alta automáticamente en el mapeo de compradores (sin comprador BC) para completarlos después.';
        }
        field(26; "Extraord. Expense G/L Account"; Code[20])
        {
            Caption = 'Cuenta gastos extraordinarios';
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting));
            ToolTip = 'Cuenta contable de los gastos extraordinarios: gastos de empleados marcados como "No deducible" en el mapeo de compradores y sin justificante. Se registran con un diario directo contra el banco Pleo, sin IVA y sin factura de proveedor.';
        }
        field(24; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Grupo IVA producto (único)';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Grupo de IVA producto que se fuerza en TODAS las líneas importadas de Pleo (gasto y activo fijo). Los importes vienen con IVA incluido y BC calcula la base hacia atrás con este grupo.';
        }

        // ---------------- DIMENSIONES ----------------
        field(30; "Project Dimension Code"; Code[20])
        {
            Caption = 'Dimensión para el proyecto';
            TableRelation = Dimension.Code;
            ToolTip = 'Dimensión de BC donde se vuelca el "Proyecto - Code" de Pleo (p.ej. PROYECTO u OBRA). Si está vacía, el proyecto no se traslada.';
        }
        field(31; "Auto Create Dim. Values"; Boolean)
        {
            Caption = 'Auto-crear valores de dimensión';
            InitValue = true;
            ToolTip = 'Si está activo, los códigos de proyecto de Pleo que no existan como valor de dimensión se crean automáticamente con su nombre.';
        }
        field(32; "Default Project Code"; Code[20])
        {
            Caption = 'Propiedad predeterminada';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Project Dimension Code"));
            ToolTip = 'Valor de dimensión de propiedad que se asigna a los gastos que vienen de Pleo sin proyecto informado. Se aplica al validar la línea (también determina el activo fijo en CAPEX). Si está vacío, las líneas sin proyecto se quedan sin dimensión de propiedad.';
        }

        // ---------------- CAPEX / ACTIVOS FIJOS ----------------
        field(70; "Auto Create Fixed Assets"; Boolean)
        {
            Caption = 'Auto-crear activos fijos';
            InitValue = true;
            ToolTip = 'Si está activo y no existe ningún activo fijo con la ubicación de la propiedad, se crea automáticamente (descripción = nombre de la propiedad, ubicación = código de la propiedad).';
        }
        field(71; "FA Subclass Code"; Code[10])
        {
            Caption = 'Subclase activo fijo';
            TableRelation = "FA Subclass";
            ToolTip = 'Subclase por defecto para los activos fijos creados automáticamente, cuando el mapeo de la categoría no indica clase ni subclase (opcional).';
        }
        field(72; "FA Posting Group"; Code[20])
        {
            Caption = 'Grupo contable activo fijo';
            TableRelation = "FA Posting Group";
            ToolTip = 'Grupo contable de activo asignado en el libro de amortización de los activos fijos creados automáticamente.';
        }
        field(73; "FA Depreciation Book Code"; Code[10])
        {
            Caption = 'Libro de amortización';
            TableRelation = "Depreciation Book";
            ToolTip = 'Libro de amortización para los activos fijos creados y para las líneas de compra CAPEX. Si se deja vacío, se usa el libro por defecto de la configuración de activos fijos.';
        }

        // ---------------- MONEDERO / CASHBACK ----------------
        field(40; "Process Wallet Loads"; Boolean)
        {
            Caption = 'Contabilizar recargas monedero';
            ToolTip = 'Si está activo, las líneas "Wallet Load" generan un diario: cargo en el banco Pleo con abono en el banco de origen. Si no, se omiten.';
        }
        field(41; "Wallet Origin Bank Account"; Code[20])
        {
            Caption = 'Banco origen de las recargas';
            TableRelation = "Bank Account"."No.";
            ToolTip = 'Banco real desde el que se transfiere dinero al monedero Pleo.';
        }
        field(50; "Process Cashbacks"; Boolean)
        {
            Caption = 'Contabilizar cashbacks';
            ToolTip = 'Si está activo, las líneas "Cashback" generan un diario: cargo en el banco Pleo con abono en la cuenta de ingresos indicada. Si no, se omiten.';
        }
        field(51; "Cashback G/L Account No."; Code[20])
        {
            Caption = 'Cuenta ingreso cashback';
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting));
            ToolTip = 'Cuenta contable de ingresos (p.ej. 759x/778x) donde abonar el cashback de Pleo.';
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
