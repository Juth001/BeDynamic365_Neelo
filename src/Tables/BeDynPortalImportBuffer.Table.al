namespace BeDynamic.PortalImport;

table 82601 "BeDyn Portal Import Buffer"
{
    Caption = 'Buffer Importación Portales';
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
        field(4; Channel; Enum "BeDyn Portal Channel")
        {
            Caption = 'Canal';
            ToolTip = 'Portal de venta del que procede el movimiento (Airbnb o Booking).';
        }

        // ---------------- DATOS DEL CSV (COMUNES) ----------------
        field(10; "Transaction Date"; Date)
        {
            Caption = 'Fecha';
            ToolTip = 'Fecha del movimiento (en Booking, la fecha del pago). Se usa como fecha de registro.';
        }
        field(11; "Row Type"; Enum "BeDyn Portal Row Type")
        {
            Caption = 'Tipo';
            ToolTip = 'Tipo de movimiento: Reserva (ingreso con comisiones) o Payout (transferencia al banco).';
        }
        field(12; "Reservation Code"; Code[20])
        {
            Caption = 'Cód. reserva';
            ToolTip = 'Identificador de la reserva en el portal: código de confirmación en Airbnb, número de referencia en Booking.';
        }
        field(13; "Start Date"; Date)
        {
            Caption = 'Fecha inicio';
            ToolTip = 'Fecha de entrada de la estancia.';
        }
        field(14; "End Date"; Date)
        {
            Caption = 'Fecha fin';
            ToolTip = 'Fecha de salida de la estancia.';
        }
        field(15; Nights; Integer)
        {
            Caption = 'Noches';
            BlankZero = true;
            ToolTip = 'Número de noches de la estancia.';
        }
        field(16; "Listing ID"; Code[20])
        {
            Caption = 'ID alojamiento';
            ToolTip = 'ID numérico del alojamiento (solo Booking). En Airbnb el alojamiento se identifica por su nombre.';
        }
        field(17; Listing; Text[100])
        {
            Caption = 'Alojamiento';
            ToolTip = 'Nombre del alojamiento en el portal. Determina la propiedad mediante el mapeo de alojamientos.';
        }
        field(18; "Currency Code"; Code[10])
        {
            Caption = 'Divisa';
            ToolTip = 'Divisa del movimiento (solo se soporta EUR).';
        }
        field(19; Amount; Decimal)
        {
            Caption = 'Importe (neto)';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'Importe neto de la reserva que el portal abona al anfitrión (bruto menos comisiones).';
        }
        field(20; "Gross Amount"; Decimal)
        {
            Caption = 'Importe bruto';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'Importe bruto de la reserva antes de descontar las comisiones del portal.';
        }
        field(21; "Commission Amount"; Decimal)
        {
            Caption = 'Comisión canal';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'Comisión principal del portal (comisión de servicio en Airbnb, comisión en Booking).';
        }
        field(22; "Payment Fee Amount"; Decimal)
        {
            Caption = 'Comisión pagos';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'Comisión adicional del portal (Pago rápido en Airbnb, cargo por servicio de pagos en Booking).';
        }
        field(23; "VAT Fee Amount"; Decimal)
        {
            Caption = 'IVA comisión';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'IVA que Booking retiene sobre sus comisiones (solo Booking).';
        }
        field(24; "Taxes Amount"; Decimal)
        {
            Caption = 'Impuestos';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'Impuestos liquidados directamente por el portal.';
        }
        field(25; "Paid Out Amount"; Decimal)
        {
            Caption = 'Cobrado';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'Importe transferido al banco (solo líneas de tipo Payout).';
        }

        // ---------------- DATOS ESPECÍFICOS AIRBNB ----------------
        field(30; "Booking Date"; Date)
        {
            Caption = 'Fecha reserva';
            ToolTip = 'Fecha en la que el viajero hizo la reserva (solo Airbnb).';
        }
        field(31; Guest; Text[100])
        {
            Caption = 'Viajero';
            ToolTip = 'Nombre del viajero de la reserva (solo Airbnb). Forma parte de la descripción de la factura.';
        }
        field(32; Details; Text[250])
        {
            Caption = 'Detalles';
            ToolTip = 'Texto de detalle de Airbnb (en los payouts, el banco de destino de la transferencia).';
        }
        field(33; "Reference Code"; Text[50])
        {
            Caption = 'Cód. referencia';
            ToolTip = 'Código de referencia del payout en Airbnb. Se usa para no importar dos veces la misma transferencia.';
        }
        field(34; "Cleaning Fee"; Decimal)
        {
            Caption = 'Gastos de limpieza';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'Gastos de limpieza cobrados al viajero (Airbnb, incluidos en los ingresos brutos).';
        }
        field(35; "Fiscal Year"; Integer)
        {
            Caption = 'Año fiscal';
            BlankZero = true;
            ToolTip = 'Año fiscal al que Airbnb asigna la reserva.';
        }
        field(36; "Estimated Arrival Date"; Date)
        {
            Caption = 'Fecha llegada estimada';
            ToolTip = 'Fecha estimada en la que el payout llega al banco (Airbnb, solo payouts).';
        }

        // ---------------- DATOS ESPECÍFICOS BOOKING ----------------
        field(40; "Payout Group ID"; Text[50])
        {
            Caption = 'Grupo payout';
            ToolTip = 'Identificador del grupo de payout de Booking. Enlaza cada payout con sus reservas.';
        }
        field(41; "Issue Date"; Date)
        {
            Caption = 'Fecha emisión';
            ToolTip = 'Fecha de emisión del cargo en Booking.';
        }
        field(42; "Reservation Status"; Text[20])
        {
            Caption = 'Estado reserva';
            ToolTip = 'Estado de la reserva en Booking. Solo se procesan las reservas con estado OK; el resto se omite para revisión manual.';
        }
        field(43; Rooms; Integer)
        {
            Caption = 'Habitaciones';
            BlankZero = true;
            ToolTip = 'Número de habitaciones de la reserva (Booking).';
        }
        field(44; "Payable Amount"; Decimal)
        {
            Caption = 'Importe a pagar';
            AutoFormatType = 1;
            BlankZero = true;
            ToolTip = 'Importe a pagar del payout según Booking (puede diferir un céntimo del importe del pago por redondeo).';
        }
        field(45; "Bank Account Mask"; Text[20])
        {
            Caption = 'Cuenta bancaria (portal)';
            ToolTip = 'Cuenta bancaria de destino enmascarada, tal y como aparece en el CSV de Booking (p.ej. *2632).';
        }

        field(48; "External ID"; Text[80])
        {
            Caption = 'Id. externo';
            ToolTip = 'Identificador único calculado del movimiento (con prefijo del canal). Se usa para no importar dos veces el mismo movimiento.';
        }

        // ---------------- RESOLUCIÓN ----------------
        field(50; "Property Code"; Code[20])
        {
            Caption = 'Propiedad';
            ToolTip = 'Código de propiedad resuelto por el mapeo de alojamientos. Se vuelca en la dimensión configurada. Se puede corregir a mano antes de procesar.';
        }
        field(51; "Variant Code"; Code[10])
        {
            Caption = 'Variante';
            ToolTip = 'Variante del producto de la propiedad para la factura, resuelta por el mapeo de alojamientos. Vacía, se usa la variante por defecto de la configuración. Se puede corregir a mano antes de procesar.';
        }

        // ---------------- ESTADO / RESULTADO ----------------
        field(60; Status; Enum "BeDyn Portal Line Status")
        {
            Caption = 'Estado';
            InitValue = Pending;
            ToolTip = 'Estado de la línea en el flujo de importación.';
        }
        field(61; "Error Message"; Text[250])
        {
            Caption = 'Mensaje';
            ToolTip = 'Motivo del error o de la omisión de la línea.';
        }
        field(62; "Warning Message"; Text[250])
        {
            Caption = 'Aviso';
            ToolTip = 'Aviso no bloqueante detectado en la validación (p.ej. los importes no cuadran). La línea se puede procesar igualmente.';
        }
        field(70; "Posted Document No."; Code[20])
        {
            Caption = 'Documento registrado';
            ToolTip = 'Número del documento registrado: la factura de venta en las reservas, el abono en los ajustes de resolución y el asiento del payout.';
        }
        field(71; "Income Posted"; Boolean)
        {
            Caption = 'Factura registrada';
            ToolTip = 'Indica que la factura (o abono) de la reserva ya se ha registrado (control de reintentos).';
        }
        field(72; "Commission Posted"; Boolean)
        {
            Caption = 'Comisión registrada';
            ToolTip = 'Indica que la comisión de la reserva ya se ha registrado (control de reintentos).';
        }
        field(73; "Created Invoice No."; Code[20])
        {
            Caption = 'Borrador factura';
            ToolTip = 'Número del borrador de factura o abono de venta creado y aún no registrado (control de reintentos).';
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
        key(External; "External ID")
        {
        }
        key(Group; "Payout Group ID", "Row Type")
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

    /// <summary>Clave del alojamiento en el mapeo: el ID en Booking, el nombre en Airbnb.</summary>
    procedure GetListingKey(): Text[100]
    begin
        if Rec."Listing ID" <> '' then
            exit(Rec."Listing ID");
        exit(Rec.Listing);
    end;

    /// <summary>Variante con la que se factura la línea: la del mapeo/línea o, en su defecto, la de la configuración.</summary>
    procedure GetEffectiveVariantCode(DefaultVariantCode: Code[10]): Code[10]
    begin
        if Rec."Variant Code" <> '' then
            exit(Rec."Variant Code");
        exit(DefaultVariantCode);
    end;
}
