namespace BeDynamic.ReservationImport;

using BeDynamic.PropertyManagement;

table 82800 "BeDyn Res. Import Line"
{
    // Línea de staging del fichero de reservas y fianzas. Guarda lo que venía en el
    // CSV tal cual (columnas "(CSV)") y, al lado, lo que la validación ha resuelto
    // contra los maestros de Business Central, para poder revisar antes de crear
    // nada.

    Caption = 'Línea importación reservas';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº movimiento';
            AutoIncrement = true;
        }
        field(2; "Batch Code"; Code[20])
        {
            Caption = 'Lote';
        }
        field(3; "Row No."; Integer)
        {
            Caption = 'Fila CSV';
        }

        // ---------------- TAL COMO VIENE EN EL FICHERO ----------------
        field(10; "External Id"; Code[50])
        {
            Caption = 'Id reserva (CSV)';
        }
        field(11; "External Code"; Code[20])
        {
            Caption = 'Cód. reserva (CSV)';
        }
        field(12; "Guest Name"; Text[100])
        {
            Caption = 'Huésped/Cliente (CSV)';
        }
        field(13; "Property Unit Text"; Text[100])
        {
            Caption = 'Propiedad/Unidad (CSV)';
        }
        field(14; "Property Code CSV"; Code[20])
        {
            Caption = 'Id propiedad (CSV)';
        }
        field(15; "Unit Code CSV"; Code[50])
        {
            Caption = 'Id unidad (CSV)';
        }
        field(16; "Check-In Date"; Date)
        {
            Caption = 'Check-in';
        }
        field(17; "Check-Out Date"; Date)
        {
            Caption = 'Check-out';
        }
        field(18; "Deposit Amount"; Decimal)
        {
            Caption = 'Fianza';
        }
        field(19; "Returned Amount"; Decimal)
        {
            Caption = 'Cantidad devuelta';
        }
        field(20; "Retained Amount"; Decimal)
        {
            Caption = 'Cantidad descontada';
        }
        field(21; "Balance Amount"; Decimal)
        {
            Caption = 'Balance (CSV)';
        }
        field(22; "Customer Type CSV"; Code[20])
        {
            Caption = 'Tipo cliente (CSV)';
        }
        field(23; "Guest Type CSV"; Code[20])
        {
            Caption = 'Tipo huésped (CSV)';
        }
        field(24; "Channel CSV"; Code[20])
        {
            Caption = 'Canal (CSV)';
        }
        field(25; "Nights CSV"; Integer)
        {
            Caption = 'Noches (CSV)';
        }
        field(26; "Contract Amount"; Decimal)
        {
            Caption = 'Importe contrato';
        }
        field(27; "Monthly Rent"; Decimal)
        {
            Caption = 'Renta mensual';
        }
        field(28; Remark; Text[250])
        {
            Caption = 'Observaciones (CSV)';
        }

        // ---------------- EMPRESA DESTINO ----------------
        field(30; "Mgt. Company Code"; Code[10])
        {
            Caption = 'Empresa gestora';
            ToolTip = 'Segundo segmento del código de propiedad, que dice de qué gestora es la reserva.';
        }
        field(31; "Target Company"; Text[30])
        {
            Caption = 'Empresa destino';
            ToolTip = 'Empresa de Business Central donde se tiene que tratar esta reserva. Las que no son de la empresa actual se envían a la suya al distribuir.';
        }

        // ---------------- RESUELTO CONTRA LOS MAESTROS ----------------
        field(40; "Property No."; Code[20])
        {
            Caption = 'Propiedad';
            TableRelation = "BeDyn Property";
        }
        field(41; "Room No."; Code[20])
        {
            Caption = 'Subpropiedad';
            TableRelation = "BeDyn Property Room"."Room No." where("Property No." = field("Property No."));
        }
        field(42; "Tenant No."; Code[20])
        {
            Caption = 'Inquilino';
            TableRelation = "BeDyn Tenant";
        }
        field(43; "Reservation No."; Code[20])
        {
            Caption = 'Reserva';
            TableRelation = "BeDyn Reservation";
        }
        field(44; "Deposit No."; Code[20])
        {
            Caption = 'Fianza creada';
            TableRelation = "BeDyn Deposit";
        }
        field(45; "New Tenant"; Boolean)
        {
            Caption = 'Alta de inquilino';
            ToolTip = 'La línea va a dar de alta un inquilino nuevo porque no hay ninguno con ese nombre.';
        }
        field(46; "Existing Reservation"; Boolean)
        {
            Caption = 'Reserva ya cargada';
            ToolTip = 'Ya existe una reserva con este Id externo. Lo que se hace con ella depende de la configuración.';
        }

        // ---------------- ESTADO ----------------
        field(50; Status; Enum "BeDyn Res. Import Status")
        {
            Caption = 'Estado';
        }
        field(51; "Error Message"; Text[250])
        {
            Caption = 'Mensaje';
        }
        field(52; "Warning Message"; Text[250])
        {
            Caption = 'Aviso';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Batch; "Batch Code", "Row No.")
        {
        }
        key(ExternalId; "Batch Code", "External Id")
        {
        }
        key(BatchStatus; "Batch Code", Status)
        {
        }
    }

    // Añade un aviso sin pisar los anteriores: una línea puede acumular varios.
    procedure AddWarning(NewWarning: Text)
    var
        SeparatorTok: Label '; ', Locked = true;
    begin
        if "Warning Message" = '' then
            "Warning Message" := CopyStr(NewWarning, 1, MaxStrLen("Warning Message"))
        else
            "Warning Message" := CopyStr("Warning Message" + SeparatorTok + NewWarning, 1, MaxStrLen("Warning Message"));
        if Status <> Status::Error then
            Status := Status::Warning;
    end;

    procedure SetError(NewError: Text)
    begin
        "Error Message" := CopyStr(NewError, 1, MaxStrLen("Error Message"));
        Status := Status::Error;
    end;
}
