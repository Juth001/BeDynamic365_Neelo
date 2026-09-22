namespace BeDynamic.PortalImport;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Neelo.RecurringInvoicing;

table 82600 "BeDyn Portal Setup"
{
    Caption = 'Configuración Importación Portales de Venta';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }

        // ---------------- GENERAL ----------------
        field(10; "File Encoding"; Option)
        {
            Caption = 'Codificación del fichero';
            OptionMembers = "UTF-8","Windows (ANSI)";
            OptionCaption = 'UTF-8,Windows (ANSI)';
            ToolTip = 'Solo se usa si el fichero no permite detectar la codificación automáticamente (sin BOM). Si los acentos salen mal al importar, prueba a cambiar esta opción.';
        }
        field(11; "Process Payouts"; Boolean)
        {
            Caption = 'Contabilizar payouts';
            InitValue = true;
            ToolTip = 'Si está activo, las líneas Payout generan el asiento del banco contra el cliente genérico. Si no, se marcan como omitidas y solo se contabilizan las reservas.';
        }
        field(12; "Process Cancelled Reservations"; Boolean)
        {
            Caption = 'Contabilizar reservas canceladas';
            ToolTip = 'Si está activo, las reservas de Booking con estado Cancelado se facturan igual que las que están en estado OK. Si no, se marcan como omitidas para revisión manual.';
        }
        field(13; "Payment Journal Template"; Code[10])
        {
            Caption = 'Libro diario de pagos';
            TableRelation = "Gen. Journal Template".Name where(Type = const(Payments));
            ToolTip = 'Libro diario donde se dejan los pagos (comisiones y payouts) cuando el registro automático de Recurring Invoicing ("Post Automatically") está desactivado, para que el usuario los registre.';

            trigger OnValidate()
            begin
                if "Payment Journal Template" <> xRec."Payment Journal Template" then
                    "Payment Journal Batch" := '';
            end;
        }
        field(14; "Payment Journal Batch"; Code[10])
        {
            Caption = 'Sección diario de pagos';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Payment Journal Template"));
            ToolTip = 'Sección del libro diario de pagos donde se dejan los apuntes cuando el registro automático está desactivado.';

            trigger OnValidate()
            begin
                if "Payment Journal Batch" <> '' then
                    TestField("Payment Journal Template");
            end;
        }

        // ---------------- VENTAS ----------------
        field(20; "Generic Customer No."; Code[20])
        {
            Caption = 'Cliente genérico';
            TableRelation = Customer."No.";
            ToolTip = 'Cliente al que se facturan todas las reservas de los portales. El código de cada reserva va como nº de documento externo de su factura.';
        }
        field(21; "Sales VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Grupo IVA producto (ventas)';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Grupo de IVA producto que se fuerza en las líneas de las facturas de reservas. Los importes de los portales vienen con IVA incluido y BC calcula la base hacia atrás con este grupo.';
        }
        field(22; "Default Variant Code"; Code[10])
        {
            Caption = 'Variante por defecto';
            TableRelation = "Item Variant".Code;
            ToolTip = 'Variante que se asigna a las líneas de las facturas de reservas. Cada producto de propiedad debe tener una variante con este código. Si está vacía, las líneas se crean sin variante.';
        }
        field(23; "Auto Create Default Variant"; Boolean)
        {
            Caption = 'Auto-crear variante por defecto';
            ToolTip = 'Si está activo y el producto de la propiedad no tiene la variante indicada en "Variante por defecto", la validación la crea automáticamente en el producto en vez de dar error.';
        }

        // ---------------- COMISIONES ----------------
        field(30; "Commission Treatment"; Enum "BeDyn Portal Commission Mode")
        {
            Caption = 'Tratamiento comisiones';
            InitValue = Vendor;
            ToolTip = 'Cargo a proveedor: las comisiones retenidas por el portal se cargan a su proveedor como pago a cuenta, y quedan neteadas cuando se registre la factura real del portal. Cuenta contable: las comisiones se llevan por diario a la cuenta de gasto configurada.';
        }
        field(31; "Commission G/L Account"; Code[20])
        {
            Caption = 'Cuenta comisiones';
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting));
            ToolTip = 'Solo en modo cuenta contable: cuenta de gasto donde se cargan las comisiones retenidas por el portal.';
        }
        field(32; "Fee VAT G/L Account"; Code[20])
        {
            Caption = 'Cuenta IVA comisiones';
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting));
            ToolTip = 'Solo en modo cuenta contable: cuenta donde se carga el IVA que Booking retiene sobre sus comisiones. Si está vacía, el IVA va a la cuenta de comisiones.';
        }

        // ---------------- DIMENSIONES ----------------
        field(40; "Property Dimension Code"; Code[20])
        {
            Caption = 'Dimensión para la propiedad';
            TableRelation = Dimension.Code;
            ToolTip = 'Dimensión de BC donde se vuelca el código de propiedad resuelto del alojamiento (p.ej. PROPIEDAD). Si está vacía, la propiedad no se traslada.';
        }
        field(41; "Auto Create Dim. Values"; Boolean)
        {
            Caption = 'Auto-crear valores de dimensión';
            InitValue = true;
            ToolTip = 'Si está activo, los códigos de propiedad que no existan como valor de dimensión se crean automáticamente al contabilizar.';
        }
        field(42; "Auto Create Listing Mapping"; Boolean)
        {
            Caption = 'Auto-crear mapeo de alojamientos';
            InitValue = true;
            ToolTip = 'Si está activo, los alojamientos desconocidos se dan de alta automáticamente en la tabla de mapeo (sin propiedad) para completarlos después.';
        }
        field(43; "Channel Dimension Code"; Code[20])
        {
            Caption = 'Dimensión para el canal';
            TableRelation = Dimension.Code;
            ToolTip = 'Dimensión de BC que identifica el canal de venta (p.ej. CANAL). Se aplica, junto con la de propiedad, a las facturas de reservas y a todos los asientos generados. Si está vacía, el canal no se traslada.';
        }

        // ---------------- AIRBNB ----------------
        field(50; "Airbnb Vendor No."; Code[20])
        {
            Caption = 'Proveedor Airbnb';
            TableRelation = Vendor."No.";
            ToolTip = 'Solo en modo cargo a proveedor: proveedor de BC de Airbnb al que se cargan las comisiones retenidas, a la espera de su factura.';
        }
        field(51; "Airbnb Payout Bank Account"; Code[20])
        {
            Caption = 'Banco payouts Airbnb';
            TableRelation = "Bank Account"."No.";
            ToolTip = 'Cuenta bancaria de BC donde Airbnb transfiere los payouts.';
        }
        field(52; "Airbnb Channel Dim. Value"; Code[20])
        {
            Caption = 'Valor de canal Airbnb';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Channel Dimension Code"));
            ToolTip = 'Valor de la dimensión de canal para los movimientos de Airbnb (p.ej. AIRBNB).';
        }
        field(53; "Airbnb Sales UoM Code"; Code[10])
        {
            Caption = 'Ud. medida ventas Airbnb';
            TableRelation = "Unit of Measure";
            ToolTip = 'Unidad de medida en la que se importan las ventas de Airbnb (normalmente noches). La línea de la factura lleva como cantidad las noches de la reserva y como precio el bruto dividido por las noches. Vacía, la línea se crea con cantidad 1 y el bruto como precio.';
        }

        // ---------------- BOOKING ----------------
        field(60; "Booking Vendor No."; Code[20])
        {
            Caption = 'Proveedor Booking';
            TableRelation = Vendor."No.";
            ToolTip = 'Solo en modo cargo a proveedor: proveedor de BC de Booking al que se cargan las comisiones e IVA retenidos, a la espera de su factura.';
        }
        field(61; "Booking Payout Bank Account"; Code[20])
        {
            Caption = 'Banco payouts Booking';
            TableRelation = "Bank Account"."No.";
            ToolTip = 'Cuenta bancaria de BC donde Booking transfiere los payouts.';
        }
        field(62; "Booking Channel Dim. Value"; Code[20])
        {
            Caption = 'Valor de canal Booking';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Channel Dimension Code"));
            ToolTip = 'Valor de la dimensión de canal para los movimientos de Booking (p.ej. BOOKING).';
        }
        field(63; "Booking Sales UoM Code"; Code[10])
        {
            Caption = 'Ud. medida ventas Booking';
            TableRelation = "Unit of Measure";
            ToolTip = 'Unidad de medida en la que se importan las ventas de Booking (normalmente noches). La línea de la factura lleva como cantidad las noches de la reserva y como precio el bruto dividido por las noches. Vacía, la línea se crea con cantidad 1 y el bruto como precio.';
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

    /// <summary>
    /// Registro automático: el parámetro "Post Automatically" de la configuración de
    /// Recurring Invoicing (compartido con la importación de colaboradores). Activo,
    /// factura y pagos se registran; desactivado, la factura queda en borrador y los
    /// pagos en el diario configurado.
    /// </summary>
    procedure AutoPostEnabled(): Boolean
    var
        RecurringSetup: Record "BeDyn Recurring Inv. Setup";
    begin
        RecurringSetup.GetSetup();
        exit(RecurringSetup."Default Posting");
    end;

    procedure GetVendorNo(Channel: Enum "BeDyn Portal Channel"): Code[20]
    begin
        case Channel of
            Channel::Airbnb:
                exit("Airbnb Vendor No.");
            Channel::Booking:
                exit("Booking Vendor No.");
        end;
    end;

    procedure GetPayoutBankAccount(Channel: Enum "BeDyn Portal Channel"): Code[20]
    begin
        case Channel of
            Channel::Airbnb:
                exit("Airbnb Payout Bank Account");
            Channel::Booking:
                exit("Booking Payout Bank Account");
        end;
    end;

    procedure GetChannelDimValue(Channel: Enum "BeDyn Portal Channel"): Code[20]
    begin
        case Channel of
            Channel::Airbnb:
                exit("Airbnb Channel Dim. Value");
            Channel::Booking:
                exit("Booking Channel Dim. Value");
        end;
    end;

    procedure GetSalesUoMCode(Channel: Enum "BeDyn Portal Channel"): Code[10]
    begin
        case Channel of
            Channel::Airbnb:
                exit("Airbnb Sales UoM Code");
            Channel::Booking:
                exit("Booking Sales UoM Code");
        end;
    end;
}
