namespace BeDynamic.PortalImport;

using System.Utilities;

codeunit 82600 "BeDyn Portal CSV Reader"
{
    // Lector unificado de los CSV de Airbnb y Booking.
    //   El canal se detecta automáticamente por la cabecera del fichero:
    //     Airbnb  -> columnas "Fecha" y "Tipo" (export de transacciones).
    //     Booking -> columnas "Tipo/Tipo de transacción" y "Fecha del pago" (export de payouts).
    //   Ambos con separador , cabecera por título de columna insensible a acentos y
    //   codificación, campos entrecomillados con comas y saltos de línea dentro.
    //   Airbnb: fechas MM/dd/yyyy, decimales mixtos. Booking: fechas ISO yyyy-MM-dd,
    //   decimales con punto y "-" = valor vacío.
    //   Deduplica por "External ID" con prefijo de canal:
    //     AB:P:<referencia> / AB:R:<confirmación>:<fecha>:<importe> / AB:A:<ídem ajustes>
    //     BK:P:<grupo>      / BK:R:<referencia>:<grupo>
    //   Codificación auto-detectada (BOM UTF-8/UTF-16, validación UTF-8, fallback ANSI).

    var
        Channel: Enum "BeDyn Portal Channel";
        // Columnas Airbnb
        ColDate: Integer;
        ColArrivalDate: Integer;
        ColType: Integer;
        ColConfirmation: Integer;
        ColBookingDate: Integer;
        ColStartDate: Integer;
        ColEndDate: Integer;
        ColNights: Integer;
        ColGuest: Integer;
        ColListing: Integer;
        ColDetails: Integer;
        ColReference: Integer;
        ColCurrency: Integer;
        ColAmount: Integer;
        ColPaidOut: Integer;
        ColServiceFee: Integer;
        ColFastPayFee: Integer;
        ColCleaningFee: Integer;
        ColGross: Integer;
        ColTaxes: Integer;
        ColFiscalYear: Integer;
        // Columnas Booking
        ColBkType: Integer;
        ColBkGroupId: Integer;
        ColBkReference: Integer;
        ColBkCheckIn: Integer;
        ColBkCheckOut: Integer;
        ColBkIssueDate: Integer;
        ColBkResStatus: Integer;
        ColBkRooms: Integer;
        ColBkNights: Integer;
        ColBkListingId: Integer;
        ColBkListingName: Integer;
        ColBkGross: Integer;
        ColBkCommission: Integer;
        ColBkPaymentCharge: Integer;
        ColBkVat: Integer;
        ColBkTaxes: Integer;
        ColBkTransaction: Integer;
        ColBkTransCurrency: Integer;
        ColBkPayable: Integer;
        ColBkPayment: Integer;
        ColBkPayCurrency: Integer;
        ColBkPaymentDate: Integer;
        ColBkBankMask: Integer;

    /// <summary>Importa el CSV detectando el canal por la cabecera. Devuelve el canal detectado.</summary>
    procedure ImportFromBlob(var TempBlob: Codeunit "Temp Blob"; BatchCode: Code[20]; var DetectedChannel: Enum "BeDyn Portal Channel"; var ImportedCount: Integer; var DuplicateCount: Integer)
    var
        InStr: InStream;
        Line: Text;
        LineFields: List of [Text];
        LineNo: Integer;
        FileEncoding: TextEncoding;
        EmptyErr: Label 'El fichero está vacío.';
        HeaderErr: Label 'No se reconoce la cabecera: no es el export de transacciones de Airbnb (columnas "Fecha" y "Tipo") ni el de payouts de Booking (columnas "Tipo de transacción" y "Fecha del pago"). Revisa que el separador sea la coma (,).';
    begin
        if not TempBlob.HasValue() then
            Error(EmptyErr);

        FileEncoding := DetectEncoding(TempBlob);

        TempBlob.CreateInStream(InStr, FileEncoding);

        ImportedCount := 0;
        DuplicateCount := 0;
        LineNo := 0;
        while not InStr.EOS() do begin
            ReadLogicalLine(InStr, Line);
            LineNo += 1;
            if Line <> '' then begin
                SplitCsvLine(Line, LineFields);
                if LineNo = 1 then begin
                    ResolveColumns(LineFields);
                    if (ColBkType <> 0) and (ColBkPaymentDate <> 0) then
                        Channel := Channel::Booking
                    else
                        if (ColDate <> 0) and (ColType <> 0) then
                            Channel := Channel::Airbnb
                        else
                            Error(HeaderErr);
                    DetectedChannel := Channel;
                end else
                    case InsertBufferLine(LineFields, LineNo, BatchCode) of
                        1:
                            ImportedCount += 1;
                        -1:
                            DuplicateCount += 1;
                    end;
            end;
        end;
    end;

    // Detecta la codificación del fichero para no fallar con "datos no válidos en la secuencia":
    //   1) BOM FF FE -> UTF-16, BOM EF BB BF -> UTF-8 (el BOM manda siempre).
    //   2) Sin BOM: si el setup fuerza Windows (ANSI), se respeta.
    //   3) Sin BOM y setup en UTF-8: se valida que el contenido sea UTF-8 legible;
    //      si no lo es (p.ej. CSV re-guardado por Excel como ANSI), se lee como Windows.
    local procedure DetectEncoding(var TempBlob: Codeunit "Temp Blob"): TextEncoding
    var
        Setup: Record "BeDyn Portal Setup";
        InStr: InStream;
        B1: Integer;
        B2: Integer;
        B3: Integer;
    begin
        TempBlob.CreateInStream(InStr);
        B1 := ReadByte(InStr);
        B2 := ReadByte(InStr);
        B3 := ReadByte(InStr);

        if (B1 = 255) and (B2 = 254) then // FF FE
            exit(TextEncoding::UTF16);
        if (B1 = 239) and (B2 = 187) and (B3 = 191) then // EF BB BF
            exit(TextEncoding::UTF8);

        Setup.GetSetup();
        if Setup."File Encoding" = Setup."File Encoding"::"Windows (ANSI)" then
            exit(TextEncoding::Windows);

        if TryReadAllAsUtf8(TempBlob) then
            exit(TextEncoding::UTF8);
        exit(TextEncoding::Windows);
    end;

    local procedure ReadByte(var InStr: InStream): Integer
    var
        B: Byte;
    begin
        if InStr.EOS() then
            exit(-1);
        InStr.Read(B);
        exit(B);
    end;

    [TryFunction]
    local procedure TryReadAllAsUtf8(var TempBlob: Codeunit "Temp Blob")
    var
        InStr: InStream;
        Line: Text;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do
            InStr.ReadText(Line);
    end;

    // Devuelve 1 = insertada, 0 = línea vacía/ignorada, -1 = duplicada.
    local procedure InsertBufferLine(LineFields: List of [Text]; RowNo: Integer; BatchCode: Code[20]): Integer
    var
        Buffer: Record "BeDyn Portal Import Buffer";
        ExistingBuffer: Record "BeDyn Portal Import Buffer";
        ExistingArchive: Record "BeDyn Portal Import Archive";
        ExternalId: Text[80];
    begin
        Buffer.Init();
        Buffer."Entry No." := 0;
        Buffer."Batch Code" := BatchCode;
        Buffer."Row No." := RowNo;
        Buffer.Channel := Channel;
        case Channel of
            Channel::Airbnb:
                if not FillAirbnbLine(Buffer, LineFields) then
                    exit(0);
            Channel::Booking:
                if not FillBookingLine(Buffer, LineFields) then
                    exit(0);
        end;

        // Duplicado si el identificador externo ya está en el staging (en cualquier
        // lote) o en el histórico (líneas archivadas tras registrarse).
        ExternalId := BuildExternalId(Buffer);
        if ExternalId <> '' then begin
            ExistingBuffer.SetCurrentKey("External ID");
            ExistingBuffer.SetRange("External ID", ExternalId);
            if not ExistingBuffer.IsEmpty() then
                exit(-1);
            ExistingArchive.SetCurrentKey("External ID");
            ExistingArchive.SetRange("External ID", ExternalId);
            if not ExistingArchive.IsEmpty() then
                exit(-1);
        end;
        Buffer."External ID" := ExternalId;

        Buffer.Status := Buffer.Status::Pending;
        Buffer.Insert(true);
        exit(1);
    end;

    local procedure FillAirbnbLine(var Buffer: Record "BeDyn Portal Import Buffer"; LineFields: List of [Text]): Boolean
    begin
        // Sin fecha y sin tipo: fila vacía o basura al final del fichero.
        if (GetField(LineFields, ColDate) = '') and (GetField(LineFields, ColType) = '') then
            exit(false);

        Buffer."Transaction Date" := ParseDateMDY(GetField(LineFields, ColDate));
        Buffer."Row Type" := ParseAirbnbRowType(GetField(LineFields, ColType));
        Buffer."Reservation Code" := CopyStr(GetField(LineFields, ColConfirmation), 1, 20);
        Buffer."Booking Date" := ParseDateMDY(GetField(LineFields, ColBookingDate));
        Buffer."Start Date" := ParseDateMDY(GetField(LineFields, ColStartDate));
        Buffer."End Date" := ParseDateMDY(GetField(LineFields, ColEndDate));
        Buffer.Nights := ParseInteger(GetField(LineFields, ColNights));
        Buffer.Guest := CopyStr(GetField(LineFields, ColGuest), 1, 100);
        Buffer.Listing := CopyStr(GetField(LineFields, ColListing), 1, 100);
        Buffer.Details := CopyStr(StripLineBreaks(GetField(LineFields, ColDetails)), 1, 250);
        Buffer."Reference Code" := CopyStr(GetField(LineFields, ColReference), 1, 50);
        Buffer."Currency Code" := CopyStr(GetField(LineFields, ColCurrency), 1, 10);
        Buffer.Amount := ParseDecimal(GetField(LineFields, ColAmount));
        Buffer."Paid Out Amount" := ParseDecimal(GetField(LineFields, ColPaidOut));
        Buffer."Commission Amount" := ParseDecimal(GetField(LineFields, ColServiceFee));
        Buffer."Payment Fee Amount" := ParseDecimal(GetField(LineFields, ColFastPayFee));
        Buffer."Cleaning Fee" := ParseDecimal(GetField(LineFields, ColCleaningFee));
        Buffer."Gross Amount" := ParseDecimal(GetField(LineFields, ColGross));
        Buffer."Taxes Amount" := ParseDecimal(GetField(LineFields, ColTaxes));
        Buffer."Fiscal Year" := ParseInteger(GetField(LineFields, ColFiscalYear));
        Buffer."Estimated Arrival Date" := ParseDateMDY(GetField(LineFields, ColArrivalDate));
        exit(true);
    end;

    local procedure FillBookingLine(var Buffer: Record "BeDyn Portal Import Buffer"; LineFields: List of [Text]): Boolean
    begin
        // Sin tipo y sin grupo: fila vacía o basura al final del fichero.
        if (GetBkField(LineFields, ColBkType) = '') and (GetBkField(LineFields, ColBkGroupId) = '') then
            exit(false);

        Buffer."Row Type" := ParseBookingRowType(GetBkField(LineFields, ColBkType));
        Buffer."Payout Group ID" := CopyStr(GetBkField(LineFields, ColBkGroupId), 1, 50);
        Buffer."Reservation Code" := CopyStr(GetBkField(LineFields, ColBkReference), 1, 20);
        Buffer."Start Date" := ParseDateYMD(GetBkField(LineFields, ColBkCheckIn));
        Buffer."End Date" := ParseDateYMD(GetBkField(LineFields, ColBkCheckOut));
        Buffer."Issue Date" := ParseDateYMD(GetBkField(LineFields, ColBkIssueDate));
        Buffer."Reservation Status" := CopyStr(GetBkField(LineFields, ColBkResStatus), 1, 20);
        Buffer.Rooms := ParseInteger(GetBkField(LineFields, ColBkRooms));
        Buffer.Nights := ParseInteger(GetBkField(LineFields, ColBkNights));
        Buffer."Listing ID" := CopyStr(GetBkField(LineFields, ColBkListingId), 1, 20);
        Buffer.Listing := CopyStr(GetBkField(LineFields, ColBkListingName), 1, 100);
        Buffer."Gross Amount" := ParseDecimal(GetBkField(LineFields, ColBkGross));
        Buffer."Commission Amount" := ParseDecimal(GetBkField(LineFields, ColBkCommission));
        Buffer."Payment Fee Amount" := ParseDecimal(GetBkField(LineFields, ColBkPaymentCharge));
        Buffer."VAT Fee Amount" := ParseDecimal(GetBkField(LineFields, ColBkVat));
        Buffer."Taxes Amount" := ParseDecimal(GetBkField(LineFields, ColBkTaxes));
        Buffer.Amount := ParseDecimal(GetBkField(LineFields, ColBkTransaction));
        Buffer."Currency Code" := CopyStr(GetBkField(LineFields, ColBkTransCurrency), 1, 10);
        Buffer."Payable Amount" := ParseDecimal(GetBkField(LineFields, ColBkPayable));
        Buffer."Paid Out Amount" := ParseDecimal(GetBkField(LineFields, ColBkPayment));
        if Buffer."Currency Code" = '' then
            Buffer."Currency Code" := CopyStr(GetBkField(LineFields, ColBkPayCurrency), 1, 10);
        // La fecha del pago es la fecha de registro de todos los movimientos de Booking.
        Buffer."Transaction Date" := ParseDateYMD(GetBkField(LineFields, ColBkPaymentDate));
        if Buffer."Transaction Date" = 0D then
            Buffer."Transaction Date" := Buffer."Issue Date";
        Buffer."Bank Account Mask" := CopyStr(GetBkField(LineFields, ColBkBankMask), 1, 20);
        exit(true);
    end;

    // Identificador único del movimiento para deduplicar entre importaciones, con
    // prefijo de canal (el mismo que aplica la migración del histórico):
    //   Airbnb:  Payout -> código de referencia; Reserva -> confirmación + fecha + importe.
    //   Booking: Payout -> ID de grupo; Reserva -> nº de referencia + ID de grupo.
    local procedure BuildExternalId(var Buffer: Record "BeDyn Portal Import Buffer"): Text[80]
    begin
        case Buffer.Channel of
            Buffer.Channel::Airbnb:
                case Buffer."Row Type" of
                    Buffer."Row Type"::Payout:
                        if Buffer."Reference Code" <> '' then
                            exit(CopyStr('AB:P:' + Buffer."Reference Code", 1, 80));
                    Buffer."Row Type"::Reservation:
                        if Buffer."Reservation Code" <> '' then
                            exit(CopyStr('AB:R:' + Buffer."Reservation Code" + ':' + Format(Buffer."Transaction Date", 0, 9) + ':' + Format(Buffer.Amount, 0, 9), 1, 80));
                    Buffer."Row Type"::Adjustment:
                        if Buffer."Reservation Code" <> '' then
                            exit(CopyStr('AB:A:' + Buffer."Reservation Code" + ':' + Format(Buffer."Transaction Date", 0, 9) + ':' + Format(Buffer.Amount, 0, 9), 1, 80));
                    Buffer."Row Type"::Other:
                        if Buffer."Reservation Code" <> '' then
                            exit(CopyStr('AB:O:' + Buffer."Reservation Code" + ':' + Format(Buffer."Transaction Date", 0, 9) + ':' + Format(Buffer.Amount, 0, 9), 1, 80));
                end;
            Buffer.Channel::Booking:
                case Buffer."Row Type" of
                    Buffer."Row Type"::Payout:
                        if Buffer."Payout Group ID" <> '' then
                            exit(CopyStr('BK:P:' + Buffer."Payout Group ID", 1, 80));
                    Buffer."Row Type"::Reservation:
                        if Buffer."Reservation Code" <> '' then
                            exit(CopyStr('BK:R:' + Buffer."Reservation Code" + ':' + Buffer."Payout Group ID", 1, 80));
                    Buffer."Row Type"::Other:
                        if Buffer."Reservation Code" <> '' then
                            exit(CopyStr('BK:O:' + Buffer."Reservation Code" + ':' + Buffer."Payout Group ID", 1, 80));
                end;
        end;
        exit('');
    end;

    local procedure ResolveColumns(LineFields: List of [Text])
    var
        i: Integer;
        h: Text;
    begin
        for i := 1 to LineFields.Count() do begin
            h := NormalizeHeader(LineFields.Get(i));
            case h of
                // -------- Airbnb (export ES/EN) --------
                'FECHA', 'DATE':
                    ColDate := i;
                'FECHADELLEGADAESTIMADA', 'ARRIVINGBYDATE':
                    ColArrivalDate := i;
                'TIPO', 'TYPE':
                    ColType := i;
                'CDIGODECONFIRMACIN', 'CONFIRMATIONCODE':
                    ColConfirmation := i;
                'FECHADELARESERVA', 'BOOKINGDATE':
                    ColBookingDate := i;
                'FECHADEINICIO', 'STARTDATE':
                    ColStartDate := i;
                'FECHADEFINALIZACIN', 'ENDDATE':
                    ColEndDate := i;
                'NOCHES', 'NIGHTS':
                    begin
                        ColNights := i;
                        ColBkNights := i;
                    end;
                'VIAJERO', 'GUEST':
                    ColGuest := i;
                'ALOJAMIENTO', 'LISTING':
                    ColListing := i;
                'DETALLES', 'DETAILS':
                    ColDetails := i;
                'CDIGODEREFERENCIA', 'REFERENCECODE', 'REFERENCE':
                    ColReference := i;
                'MONEDA', 'CURRENCY':
                    ColCurrency := i;
                'IMPORTE', 'AMOUNT':
                    ColAmount := i;
                'COBRADO', 'PAIDOUT':
                    ColPaidOut := i;
                'COMISINDESERVICIO', 'SERVICEFEE':
                    ColServiceFee := i;
                'COMISINPORPAGORPIDO', 'FASTPAYFEE':
                    ColFastPayFee := i;
                'GASTOSDELIMPIEZA', 'CLEANINGFEE':
                    ColCleaningFee := i;
                'INGRESOSBRUTOS', 'GROSSEARNINGS':
                    ColGross := i;
                'IMPUESTOSLIQUIDADOSPORAIRBNB', 'OCCUPANCYTAXES':
                    ColTaxes := i;
                'AOFISCAL', 'EARNINGSYEAR':
                    ColFiscalYear := i;
                // -------- Booking (export ES) --------
                'TIPOTIPODETRANSACCIN':
                    ColBkType := i;
                'DESCRIPCINDELCARGO':
                    ColBkGroupId := i;
                'NMERODEREFERENCIA':
                    ColBkReference := i;
                'FECHADECHECK-IN':
                    ColBkCheckIn := i;
                'FECHADECHECK-OUT':
                    ColBkCheckOut := i;
                'FECHADEEMISIN':
                    ColBkIssueDate := i;
                'ESTADODELARESERVA':
                    ColBkResStatus := i;
                'HABITACIONES':
                    ColBkRooms := i;
                'IDDELALOJAMIENTO':
                    ColBkListingId := i;
                'NOMBREDELALOJAMIENTO':
                    ColBkListingName := i;
                'IMPORTEBRUTO':
                    ColBkGross := i;
                'COMISIN':
                    ColBkCommission := i;
                'CARGOPORSERVICIODELOSPAGOS':
                    ColBkPaymentCharge := i;
                'IVA':
                    ColBkVat := i;
                'IMPUESTOS':
                    ColBkTaxes := i;
                'IMPORTEDELATRANSACCIN':
                    ColBkTransaction := i;
                'MONEDADELATRANSACCIN':
                    ColBkTransCurrency := i;
                'IMPORTEAPAGAR':
                    ColBkPayable := i;
                'IMPORTEDELPAGO':
                    ColBkPayment := i;
                'MONEDADELPAGO':
                    ColBkPayCurrency := i;
                'FECHADELPAGO':
                    ColBkPaymentDate := i;
                'CUENTABANCARIA':
                    ColBkBankMask := i;
            end;
        end;
    end;

    // Normaliza un título de cabecera: mayúsculas y solo A-Z, 0-9, punto, guion y %.
    // Así se eliminan espacios, acentos, barras, BOM y cualquier carácter raro de
    // codificación ("Código de confirmación" -> CDIGODECONFIRMACIN).
    local procedure NormalizeHeader(HeaderText: Text): Text
    var
        Builder: TextBuilder;
        i: Integer;
        Ch: Char;
    begin
        HeaderText := UpperCase(HeaderText);
        for i := 1 to StrLen(HeaderText) do begin
            Ch := HeaderText[i];
            if ((Ch >= 'A') and (Ch <= 'Z')) or ((Ch >= '0') and (Ch <= '9')) or (Ch = '.') or (Ch = '-') or (Ch = '%') then
                Builder.Append(Ch);
        end;
        exit(Builder.ToText());
    end;

    // Lee una "línea lógica" del CSV: si una línea física deja una comilla abierta
    // (nº impar de comillas), el campo continúa en la siguiente línea física.
    local procedure ReadLogicalLine(var InStr: InStream; var Line: Text)
    var
        Part: Text;
    begin
        InStr.ReadText(Line);
        while ((CountQuotes(Line) mod 2) = 1) and (not InStr.EOS()) do begin
            InStr.ReadText(Part);
            Line += ' ' + Part;
        end;
    end;

    local procedure CountQuotes(Value: Text) Count: Integer
    var
        i: Integer;
    begin
        for i := 1 to StrLen(Value) do
            if Value[i] = '"' then
                Count += 1;
    end;

    // Divide una línea por , respetando campos entrecomillados ("" = comilla escapada).
    local procedure SplitCsvLine(Line: Text; var LineFields: List of [Text])
    var
        Builder: TextBuilder;
        i: Integer;
        Ch: Char;
        InQuotes: Boolean;
        JustClosedQuote: Boolean;
    begin
        Clear(LineFields);
        Clear(Builder);
        InQuotes := false;
        JustClosedQuote := false;
        for i := 1 to StrLen(Line) do begin
            Ch := Line[i];
            if InQuotes then begin
                if Ch = '"' then begin
                    InQuotes := false;
                    JustClosedQuote := true;
                end else
                    Builder.Append(Ch);
            end else
                case Ch of
                    '"':
                        begin
                            if JustClosedQuote then
                                Builder.Append('"'); // comilla escapada ""
                            InQuotes := true;
                            JustClosedQuote := false;
                        end;
                    ',':
                        begin
                            LineFields.Add(Builder.ToText());
                            Clear(Builder);
                            JustClosedQuote := false;
                        end;
                    else begin
                        Builder.Append(Ch);
                        JustClosedQuote := false;
                    end;
                end;
        end;
        LineFields.Add(Builder.ToText());
    end;

    local procedure GetField(LineFields: List of [Text]; Idx: Integer): Text
    begin
        if (Idx <= 0) or (Idx > LineFields.Count()) then
            exit('');
        exit(DelChr(LineFields.Get(Idx), '<>', ' '));
    end;

    // Campo de Booking: el guion "-" significa "sin valor".
    local procedure GetBkField(LineFields: List of [Text]; Idx: Integer): Text
    var
        Value: Text;
    begin
        Value := GetField(LineFields, Idx);
        if Value = '-' then
            exit('');
        exit(Value);
    end;

    local procedure ParseAirbnbRowType(Value: Text): Enum "BeDyn Portal Row Type"
    var
        Upper: Text;
    begin
        Upper := UpperCase(DelChr(Value, '<>', ' '));
        if Upper = 'PAYOUT' then
            exit("BeDyn Portal Row Type"::Payout);
        if Upper in ['RESERVA', 'RESERVATION'] then
            exit("BeDyn Portal Row Type"::Reservation);
        if Upper.Contains('AJUSTE') or Upper.Contains('ADJUSTMENT') or Upper.Contains('RESOLUC') or Upper.Contains('RESOLUT') then
            exit("BeDyn Portal Row Type"::Adjustment);
        exit("BeDyn Portal Row Type"::Other);
    end;

    local procedure ParseBookingRowType(Value: Text): Enum "BeDyn Portal Row Type"
    var
        Upper: Text;
    begin
        // "(Payout)" viene entre paréntesis en el CSV.
        Upper := UpperCase(DelChr(Value, '=', '() '));
        if Upper = 'PAYOUT' then
            exit("BeDyn Portal Row Type"::Payout);
        if Upper in ['RESERVA', 'RESERVATION'] then
            exit("BeDyn Portal Row Type"::Reservation);
        exit("BeDyn Portal Row Type"::Other);
    end;

    // Decimales mixtos: punto en campos sin comillas (519.67) y coma decimal en
    // campos entrecomillados ("95,33"). El último separador que aparece se toma
    // como decimal y el otro como separador de miles.
    local procedure ParseDecimal(Txt: Text) Result: Decimal
    var
        CommaPos: Integer;
        DotPos: Integer;
    begin
        Txt := DelChr(Txt, '=', ' ');
        if Txt = '' then
            exit(0);
        CommaPos := Txt.LastIndexOf(',');
        DotPos := Txt.LastIndexOf('.');
        if CommaPos > DotPos then begin
            Txt := Txt.Replace('.', '');
            Txt := Txt.Replace(',', '.');
        end else
            Txt := Txt.Replace(',', '');
        if not Evaluate(Result, Txt, 9) then
            Result := 0;
    end;

    local procedure ParseInteger(Txt: Text) Result: Integer
    begin
        if Txt = '' then
            exit(0);
        if not Evaluate(Result, Txt, 9) then
            Result := 0;
    end;

    // Fechas de Airbnb en formato americano MM/dd/yyyy.
    local procedure ParseDateMDY(Txt: Text) Result: Date
    var
        DayPart: Integer;
        MonthPart: Integer;
        YearPart: Integer;
        Parts: List of [Text];
    begin
        if Txt = '' then
            exit(0D);
        Parts := Txt.Split('/');
        if Parts.Count() <> 3 then begin
            if Evaluate(Result, Txt) then
                exit(Result);
            exit(0D);
        end;
        if not Evaluate(MonthPart, Parts.Get(1)) then
            exit(0D);
        if not Evaluate(DayPart, Parts.Get(2)) then
            exit(0D);
        if not Evaluate(YearPart, Parts.Get(3)) then
            exit(0D);
        if (DayPart < 1) or (MonthPart < 1) or (YearPart < 1900) then
            exit(0D);
        Result := DMY2Date(DayPart, MonthPart, YearPart);
    end;

    // Fechas de Booking en formato ISO yyyy-MM-dd.
    local procedure ParseDateYMD(Txt: Text) Result: Date
    var
        DayPart: Integer;
        MonthPart: Integer;
        YearPart: Integer;
        Parts: List of [Text];
    begin
        if Txt = '' then
            exit(0D);
        Parts := Txt.Split('-');
        if Parts.Count() <> 3 then begin
            if Evaluate(Result, Txt) then
                exit(Result);
            exit(0D);
        end;
        if not Evaluate(YearPart, Parts.Get(1)) then
            exit(0D);
        if not Evaluate(MonthPart, Parts.Get(2)) then
            exit(0D);
        if not Evaluate(DayPart, Parts.Get(3)) then
            exit(0D);
        if (DayPart < 1) or (MonthPart < 1) or (YearPart < 1900) then
            exit(0D);
        Result := DMY2Date(DayPart, MonthPart, YearPart);
    end;

    local procedure StripLineBreaks(Value: Text): Text
    var
        Builder: TextBuilder;
        i: Integer;
        Ch: Char;
    begin
        for i := 1 to StrLen(Value) do begin
            Ch := Value[i];
            if (Ch = 13) or (Ch = 10) then
                Builder.Append(' ')
            else
                Builder.Append(Ch);
        end;
        exit(DelChr(Builder.ToText(), '<>', ' '));
    end;
}
