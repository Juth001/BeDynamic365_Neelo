namespace BeDynamic.ReservationImport;

using System.Utilities;

codeunit 82800 "BeDyn Res. CSV Reader"
{
    // Lee el fichero de cuadre de reservas y fianzas a la hoja de importación.
    //
    // El fichero trae dos filas de encabezado (la de títulos y otra con las
    // instrucciones de negocio de cada columna) y una fila final de totales. Las
    // tres se descartan por el mismo criterio: una fila solo es una reserva si
    // trae Id y al menos una de las dos fechas es una fecha de verdad.
    //
    // Ojo con dos trampas del formato: la fila de títulos tiene campos
    // entrecomillados con saltos de línea dentro, y las columnas 10 y 11 se llaman
    // igual ("Cantidad Devuelta") aunque una es la devolución y la otra el
    // descuento. Por eso se lee por posición y con lectura de línea lógica.

    procedure ImportCSV(): Code[20]
    var
        TempBlob: Codeunit "Temp Blob";
        ImportLine: Record "BeDyn Res. Import Line";
        FileInStr: InStream;
        BlobInStr: InStream;
        BlobOutStr: OutStream;
        FileName: Text;
        Line: Text;
        BatchCode: Code[20];
        RowNo: Integer;
        ImportedRows: Integer;
        SkippedRows: Integer;
        FileEncoding: TextEncoding;
        UploadDialogTxt: Label 'Seleccione el fichero de reservas y fianzas';
        FileFilterTxt: Label 'Ficheros CSV (*.csv)|*.csv|Todos los ficheros (*.*)|*.*';
        NoRowsErr: Label 'El fichero no tiene ninguna fila de reserva reconocible. Se esperan columnas separadas por punto y coma, con el Id de reserva en la primera y las fechas de check-in y check-out en la séptima y la octava.';
        ImportedMsg: Label 'Importadas %1 filas en el lote %2. Se han descartado %3 filas sin Id de reserva o sin fechas (encabezados y totales).', Comment = '%1 = filas importadas, %2 = lote, %3 = filas descartadas';
    begin
        if not UploadIntoStream(UploadDialogTxt, '', FileFilterTxt, FileName, FileInStr) then
            exit('');

        TempBlob.CreateOutStream(BlobOutStr);
        CopyStream(BlobOutStr, FileInStr);
        FileEncoding := DetectEncoding(TempBlob);
        TempBlob.CreateInStream(BlobInStr, FileEncoding);

        BatchCode := GenerateBatchCode();
        while not BlobInStr.EOS() do begin
            ReadLogicalLine(BlobInStr, Line);
            RowNo += 1;
            if ProcessRow(Line, RowNo, BatchCode) then
                ImportedRows += 1
            else
                SkippedRows += 1;
        end;

        if ImportedRows = 0 then begin
            ImportLine.SetRange("Batch Code", BatchCode);
            ImportLine.DeleteAll();
            Error(NoRowsErr);
        end;

        Message(ImportedMsg, ImportedRows, BatchCode, SkippedRows);
        exit(BatchCode);
    end;

    // Devuelve si la fila era una reserva. Los encabezados, la fila de
    // instrucciones y la de totales caen aquí y se cuentan como descartadas.
    local procedure ProcessRow(Line: Text; RowNo: Integer; BatchCode: Code[20]): Boolean
    var
        ImportLine: Record "BeDyn Res. Import Line";
        LineFields: List of [Text];
        CheckIn: Date;
        CheckOut: Date;
        ExternalId: Text;
    begin
        if DelChr(Line, '<>', ' ;') = '' then
            exit(false);

        SplitCsvLine(Line, LineFields);

        ExternalId := DelChr(GetRaw(LineFields, 1), '<>', ' ');
        CheckIn := ParseDate(GetRaw(LineFields, 7));
        CheckOut := ParseDate(GetRaw(LineFields, 8));

        // Sin Id no hay reserva (fila de totales); sin ninguna fecha válida
        // tampoco (fila de títulos y fila de instrucciones).
        if ExternalId = '' then
            exit(false);
        if (CheckIn = 0D) and (CheckOut = 0D) then
            exit(false);

        ImportLine.Init();
        ImportLine."Batch Code" := BatchCode;
        ImportLine."Row No." := RowNo;
        ImportLine."External Id" := CopyStr(ExternalId, 1, MaxStrLen(ImportLine."External Id"));
        ImportLine."External Code" := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 2), '<>', ' ')), 1, MaxStrLen(ImportLine."External Code"));
        ImportLine."Guest Name" := CopyStr(DelChr(GetRaw(LineFields, 3), '<>', ' '), 1, MaxStrLen(ImportLine."Guest Name"));
        ImportLine."Property Unit Text" := CopyStr(DelChr(GetRaw(LineFields, 4), '<>', ' '), 1, MaxStrLen(ImportLine."Property Unit Text"));
        ImportLine."Property Code CSV" := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 5), '<>', ' ')), 1, MaxStrLen(ImportLine."Property Code CSV"));
        ImportLine."Unit Code CSV" := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 6), '<>', ' ')), 1, MaxStrLen(ImportLine."Unit Code CSV"));
        ImportLine."Check-In Date" := CheckIn;
        ImportLine."Check-Out Date" := CheckOut;
        ImportLine."Deposit Amount" := ParseDecimal(GetRaw(LineFields, 9));
        ImportLine."Returned Amount" := ParseDecimal(GetRaw(LineFields, 10));
        ImportLine."Retained Amount" := ParseDecimal(GetRaw(LineFields, 11));
        ImportLine."Balance Amount" := ParseDecimal(GetRaw(LineFields, 12));
        ImportLine."Customer Type CSV" := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 13), '<>', ' ')), 1, MaxStrLen(ImportLine."Customer Type CSV"));
        ImportLine."Guest Type CSV" := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 14), '<>', ' ')), 1, MaxStrLen(ImportLine."Guest Type CSV"));
        ImportLine."Channel CSV" := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 15), '<>', ' ')), 1, MaxStrLen(ImportLine."Channel CSV"));
        ImportLine."Nights CSV" := ParseInteger(GetRaw(LineFields, 16));
        ImportLine."Contract Amount" := ParseDecimal(GetRaw(LineFields, 17));
        ImportLine."Monthly Rent" := ParseDecimal(GetRaw(LineFields, 18));
        ImportLine.Remark := CopyStr(JoinRemarks(LineFields), 1, MaxStrLen(ImportLine.Remark));
        ImportLine.Status := ImportLine.Status::Pending;
        ImportLine.Insert(true);
        exit(true);
    end;

    // Las tres últimas columnas no tienen título y llevan anotaciones sueltas del
    // cuadre ("No encontrada en pasarela", reubicaciones...): se juntan en una.
    local procedure JoinRemarks(LineFields: List of [Text]) Result: Text
    var
        i: Integer;
        Part: Text;
        SeparatorTok: Label ' | ', Locked = true;
    begin
        for i := 19 to 21 do begin
            Part := DelChr(GetRaw(LineFields, i), '<>', ' ');
            if Part <> '' then begin
                if Result <> '' then
                    Result += SeparatorTok;
                Result += Part;
            end;
        end;
    end;

    local procedure GetRaw(LineFields: List of [Text]; Pos: Integer): Text
    begin
        if (Pos < 1) or (Pos > LineFields.Count()) then
            exit('');
        exit(LineFields.Get(Pos));
    end;

    // ============================ PARSEO ============================

    // Importes en formato español, tolerando símbolo de moneda: se conservan solo
    // dígitos y separadores y se convierte 1.234,56 -> 1234.56. El fichero mezcla
    // importes con y sin formato (550 junto a 1.500,00), y los admite los dos.
    local procedure ParseDecimal(Txt: Text) Result: Decimal
    var
        Clean: Text;
    begin
        Clean := DelChr(Txt, '=', DelChr(Txt, '=', '0123456789,.-'));
        if Clean in ['', '-', ',', '.'] then
            exit(0);
        if Clean.Contains(',') then
            Clean := DelChr(Clean, '=', '.');
        Clean := ConvertStr(Clean, ',', '.');
        if not Evaluate(Result, Clean, 9) then
            exit(0);
    end;

    local procedure ParseInteger(Txt: Text) Result: Integer
    var
        Clean: Text;
    begin
        Clean := DelChr(Txt, '=', DelChr(Txt, '=', '0123456789-'));
        if Clean in ['', '-'] then
            exit(0);
        if not Evaluate(Result, Clean) then
            exit(0);
    end;

    // Fechas d/M/yyyy con día y mes de una o dos cifras (2/01/2025, 1/4/2025...).
    local procedure ParseDate(Txt: Text): Date
    var
        Parts: List of [Text];
        D: Integer;
        M: Integer;
        Y: Integer;
    begin
        Txt := DelChr(Txt, '<>', ' ');
        Parts := Txt.Split('/');
        if Parts.Count() <> 3 then
            exit(0D);
        if not Evaluate(D, Parts.Get(1)) then
            exit(0D);
        if not Evaluate(M, Parts.Get(2)) then
            exit(0D);
        if not Evaluate(Y, Parts.Get(3)) then
            exit(0D);
        if (Y < 2000) or (Y > 2100) or (M < 1) or (M > 12) or (D < 1) then
            exit(0D);
        // Día que no existe en el mes (31/4, 30/2...): DMY2Date daría
        // "La fecha no es válida"; la fila se descarta como fila sin fecha.
        if D > Date2DMY(CalcDate('<CM>', DMY2Date(1, M, Y)), 1) then
            exit(0D);
        exit(DMY2Date(D, M, Y));
    end;

    local procedure GenerateBatchCode(): Code[20]
    begin
        exit(CopyStr('RES' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20));
    end;

    // ============================ LECTURA CSV ============================

    // Lee una línea lógica: si un campo entrecomillado contiene saltos de línea,
    // une las líneas físicas hasta cerrar las comillas. Imprescindible aquí: la
    // fila de títulos parte "Cantidad Devuelta" en dos líneas.
    local procedure ReadLogicalLine(var InStr: InStream; var Line: Text)
    var
        Physical: Text;
    begin
        InStr.ReadText(Line);
        while (CountQuotes(Line) mod 2 = 1) and (not InStr.EOS()) do begin
            InStr.ReadText(Physical);
            Line += ' ' + Physical;
        end;
    end;

    local procedure CountQuotes(Txt: Text): Integer
    begin
        exit(StrLen(Txt) - StrLen(DelChr(Txt, '=', '"')));
    end;

    // Divide una línea por ; respetando campos entrecomillados y comillas escapadas "".
    local procedure SplitCsvLine(Line: Text; var LineFields: List of [Text])
    var
        CurrentField: Text;
        i: Integer;
        Len: Integer;
        Ch: Char;
        InQuotes: Boolean;
    begin
        Clear(LineFields);
        Len := StrLen(Line);
        i := 1;
        while i <= Len do begin
            Ch := Line[i];
            if InQuotes then
                case Ch of
                    '"':
                        if (i < Len) and (Line[i + 1] = '"') then begin
                            CurrentField += '"';
                            i += 1;
                        end else
                            InQuotes := false;
                    else
                        CurrentField += Ch;
                end
            else
                case Ch of
                    '"':
                        InQuotes := true;
                    ';':
                        begin
                            LineFields.Add(CurrentField);
                            CurrentField := '';
                        end;
                    else
                        CurrentField += Ch;
                end;
            i += 1;
        end;
        LineFields.Add(CurrentField);
    end;

    // ============================ CODIFICACIÓN ============================

    // BOM UTF-8/UTF-16 manda; sin BOM se intenta UTF-8 y, si el contenido no es
    // UTF-8 válido (CSV re-guardado por Excel como ANSI), se lee como Windows.
    local procedure DetectEncoding(var TempBlob: Codeunit "Temp Blob"): TextEncoding
    var
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
}
