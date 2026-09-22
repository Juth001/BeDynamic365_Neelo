namespace BeDynamic.PropertyManagement;

using BeDynamic.CleaningImport;
using BeDynamic.ReservationImport;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Purchases.Vendor;

table 82500 "BeDyn Property Mgt. Setup"
{
    Caption = 'Configuración gestión propiedades';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(2; "Owner Nos."; Code[20])
        {
            Caption = 'N.º serie propietario';
            TableRelation = "No. Series";
        }
        field(3; "Property Nos."; Code[20])
        {
            Caption = 'N.º serie propiedad';
            TableRelation = "No. Series";
        }
        field(4; "Contract Nos."; Code[20])
        {
            Caption = 'N.º serie contrato';
            TableRelation = "No. Series";
        }
        field(5; "Tenant Nos."; Code[20])
        {
            Caption = 'N.º serie inquilino';
            TableRelation = "No. Series";
        }
        field(6; "Reservation Nos."; Code[20])
        {
            Caption = 'N.º serie reserva';
            TableRelation = "No. Series";
        }
        field(9; "Master Room Code"; Code[20])
        {
            Caption = 'Cód. subpropiedad master';

            trigger OnValidate()
            var
                PropertyRoom: Record "BeDyn Property Room";
            begin
                if "Master Room Code" = xRec."Master Room Code" then
                    exit;
                PropertyRoom.SetRange("Master Room", true);
                PropertyRoom.ModifyAll("Master Room", false);
                PropertyRoom.Reset();
                if "Master Room Code" <> '' then begin
                    PropertyRoom.SetRange("Room No.", "Master Room Code");
                    PropertyRoom.ModifyAll("Master Room", true);
                end;
            end;
        }
        field(10; "Night Unit of Measure Code"; Code[10])
        {
            Caption = 'Cód. unidad medida noche';
            TableRelation = "Unit of Measure";
        }
        field(11; "Month Unit of Measure Code"; Code[10])
        {
            Caption = 'Cód. unidad medida mes';
            TableRelation = "Unit of Measure";
        }
        field(12; "Def. Billing Moment"; Enum "BeDyn Billing Moment")
        {
            Caption = 'Momento facturación por defecto';
        }
        field(13; "Deposit Nos."; Code[20])
        {
            Caption = 'N.º serie fianza';
            TableRelation = "No. Series";
        }
        field(14; "Deposit G/L Account No."; Code[20])
        {
            Caption = 'Cuenta fianzas';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false), "Direct Posting" = const(true));
        }
        field(15; "Deposit Billing Method"; Enum "BeDyn Deposit Billing Method")
        {
            Caption = 'Cobro de la fianza';
        }
        field(16; "Auto-Post Rental Invoices"; Boolean)
        {
            Caption = 'Registrar facturas automáticamente';
        }
        field(17; "Service G/L Account No."; Code[20])
        {
            Caption = 'Cuenta servicios por defecto';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false), "Direct Posting" = const(true));
        }
        field(18; "Property Dim. Source"; Enum "BeDyn Property Dim. Source")
        {
            Caption = 'Trabajar con';
            ToolTip = 'Origen de las dimensiones de propiedad que heredan las líneas de reclasificación: las dimensiones predeterminadas de la propiedad con ese código, o las del producto asociado a la propiedad.';
        }

        // ---------------- SERVICIOS DE LIMPIEZA (proveedor externo) ----------------
        field(20; "Cleaning Vendor No."; Code[20])
        {
            Caption = 'Proveedor habitual limpiezas';
            TableRelation = Vendor."No.";
            ToolTip = 'Proveedor que se propone al importar el fichero de servicios. Los servicios, cuentas, tareas y precios de cada proveedor se configuran en el catálogo de servicios de limpieza.';
        }
        field(21; "Cleaning Bridge Account No."; Code[20])
        {
            Caption = 'Cuenta puente limpiezas';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false), "Direct Posting" = const(true));
            ToolTip = 'Cuenta donde se registra el gasto global de la factura del proveedor de limpieza. La reclasificación la abona (dejándola a cero) contra las cuentas de gasto reales con proyecto, tarea y dimensión.';
        }
        field(22; "Cleaning Posting Mode"; Enum "BeDyn Cleaning Posting Mode")
        {
            Caption = 'Modo registro limpiezas';
            ToolTip = 'Agregado: una línea de diario por propiedad, servicio y mes. Detallado: una línea de diario por cada fila del fichero. En ambos casos el detalle completo se conserva en la hoja de importación.';
        }
        field(23; "Cleaning Auto Post Reclass"; Boolean)
        {
            Caption = 'Registrar reclasificación automáticamente';
            ToolTip = 'Si está activado, el diario de reclasificación se registra automáticamente al generarlo. Si no, las líneas quedan preparadas en la sección de diario para revisarlas y registrarlas a mano.';
        }
        field(24; "Cleaning Jnl. Template Name"; Code[10])
        {
            Caption = 'Libro diario reclasificación';
            TableRelation = "Gen. Journal Template" where(Type = const(General), Recurring = const(false));
            ToolTip = 'Libro de diario general donde se generan las líneas de reclasificación del gasto de limpiezas.';

            trigger OnValidate()
            begin
                if "Cleaning Jnl. Template Name" <> xRec."Cleaning Jnl. Template Name" then
                    "Cleaning Jnl. Batch Name" := '';
            end;
        }
        field(25; "Cleaning Jnl. Batch Name"; Code[10])
        {
            Caption = 'Sección diario reclasificación';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Cleaning Jnl. Template Name"));
            ToolTip = 'Sección del diario donde se generan las líneas de reclasificación. Conviene una sección dedicada: con el registro automático activado se registra la sección completa.';
        }
        field(26; "Cleaning Match Tolerance"; Decimal)
        {
            Caption = 'Tolerancia cuadre factura';
            DecimalPlaces = 2 : 2;
            MinValue = 0;
            ToolTip = 'Diferencia máxima admitida (en euros) entre la base imponible de la factura del proveedor y la suma de las líneas de limpieza asignadas a ella.';
        }
        field(27; "Cleaning Check Acc. Period"; Boolean)
        {
            Caption = 'Validar periodo contable';
            ToolTip = 'Al validar las líneas importadas, comprueba que la fecha de registro (fin del mes del servicio) cae en un periodo contable definido y no cerrado.';
        }
        field(28; "Cleaning Check GL Setup Date"; Boolean)
        {
            Caption = 'Validar fechas conf. contabilidad';
            ToolTip = 'Al validar las líneas importadas, comprueba la fecha de registro contra "Permitir registro desde/hasta" de la configuración de contabilidad, igual que hace el estándar al registrar.';
        }
        field(29; "Cleaning Check User Setup Date"; Boolean)
        {
            Caption = 'Validar fechas conf. usuarios';
            ToolTip = 'Al validar las líneas importadas, comprueba la fecha de registro contra "Permitir registro desde/hasta" del usuario actual en la configuración de usuarios, igual que hace el estándar al registrar. Si el usuario no tiene registro en configuración de usuarios, esta comprobación no aplica.';
        }

        // ---------------- CONTABILIDAD DE FIANZAS ----------------
        field(38; "Deposit Bridge Account No."; Code[20])
        {
            Caption = 'Cuenta puente fianzas';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false), "Direct Posting" = const(true));
            ToolTip = 'Cuenta donde entran los cobros de fianzas antes de conciliarlos con el banco o la pasarela de pago. Al registrar una fianza se carga esta cuenta y se abona la cuenta de fianzas.';
        }
        field(39; "Post Deposits on Import"; Boolean)
        {
            Caption = 'Contabilizar fianzas al importar';
            InitValue = true;
            ToolTip = 'Registra el asiento de cada fianza en cuanto se procesa la línea de importación. Desactivado, las fianzas se crean sin apunte y se pueden registrar después desde su ficha.';
        }

        // ---------------- IMPORTACIÓN DE RESERVAS ----------------
        field(35; "Channel Dimension Code"; Code[20])
        {
            Caption = 'Dimensión canal';
            TableRelation = Dimension.Code;
            ToolTip = 'Dimensión cuyos valores son los canales de entrada de las reservas (Direct, website, Gestion…). El canal de cada reserva se guarda como valor de esta dimensión en su conjunto de dimensiones.';
        }
        field(36; "Res. Import Duplicate Action"; Enum "BeDyn Res. Duplicate Action")
        {
            Caption = 'Reservas ya cargadas';
            ToolTip = 'Qué hacer cuando el fichero trae una reserva cuyo Id externo ya existe: avisar mostrando las diferencias sin tocar nada, actualizarla con los datos del fichero, o dar error y bloquear la línea.';
        }
        field(37; "Res. Import Create Masters"; Boolean)
        {
            Caption = 'Crear inquilinos y tipos que falten';
            InitValue = true;
            ToolTip = 'Da de alta automáticamente los inquilinos, tipos de cliente y tipos de huésped que vengan en el fichero y no existan. Los canales nunca se crean solos: son valores de dimensión y la línea queda en error para darlos de alta a mano.';
        }

        // ---------------- NUMERACIÓN ENLAZADA DE LOS 4 MAESTROS ----------------
        field(30; "Link Property Codes"; Boolean)
        {
            Caption = 'Numeración enlazada de maestros';
            InitValue = true;
            ToolTip = 'Mantiene el mismo código en los cuatro maestros de cada propiedad: producto, valor de dimensión, proyecto y propiedad. Al cambiar el código en cualquiera de ellos se pide confirmación y se renombra también en los otros tres. Solo pueden hacerlo los usuarios con "Puede renumerar propiedades" marcado en la configuración de usuarios.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetInstance()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}
