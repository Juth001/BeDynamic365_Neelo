namespace BeDynamic.PleoImport;

using System.Utilities;

codeunit 82100 "BeDyn Pleo CSV Reader"
{
    // Lector del CSV exportado de Pleo.
    //   Separador ; · decimal coma · fechas dd/MM/yyyy · cabecera por título de columna.
    //   Soporta campos entrecomillados con ; y saltos de línea dentro (columna Note).
    //   Deduplica por "Expense ID": un gasto ya importado en cualquier lote no se vuelve a insertar.
    //   Codificación auto-detectada (BOM UTF-8/UTF-16, validación UTF-8, fallback ANSI).

    var
        ColDate: Integer;
        ColReceipt: Integer;
        ColExpenseType: Integer;
        ColAmount: Integer;
        ColCurrency: Integer;
        ColSourceDesc: Integer;
        ColCategory: Integer;
        ColOwner: Integer;
        ColNote: Integer;
        ColTeam: Integer;
        ColReceiptUrls: Integer;
        ColExpenseId: Integer;
        ColProjectName: Integer;
        ColProjectCode: Integer;
        ColCostTypeName: Integer;
        ColCostTypeCode: Integer;
        ColVendorName: Integer;
        ColVendorCode: Integer;

    procedure ImportFromBlob(var TempBlob: Codeunit "Temp Blob"; BatchCode: Code[20]; var ImportedCount: Integer; var DuplicateCount: Integer)
    var
        InStr: InStream;
        Line: Text;
        LineFields: List of [Text];
        LineNo: Integer;
        FileEncoding: TextEncoding;
        EmptyErr: Label 'El fichero está vacío.';
        HeaderErr: Label 'No se encontró la cabecera con las columnas "Date" y "Amount". Revisa que sea el export de Pleo con punto y coma (;) como separador.';
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
                    if (ColDate = 0) or (ColAmount = 0) then
                        Error(HeaderErr);
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
        Setup: Record "BeDyn Pleo Setup";
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
        Buffer: Record "BeDyn Pleo Import Buffer";
        ExistingBuffer: Record "BeDyn Pleo Import Buffer";
        ExistingArchive: Record "BeDyn Pleo Expense Archive";
        ExpenseId: Text[50];
    begin
        // Sin fecha y sin importe: fila vacía o basura al final del fichero.
        if (GetField(LineFields, ColDate) = '') and (GetField(LineFields, ColAmount) = '') then
            exit(0);

        // Duplicado si el Expense ID ya está en el staging o en el archivo.
        ExpenseId := CopyStr(GetField(LineFields, ColExpenseId), 1, 50);
        if ExpenseId <> '' then begin
            ExistingBuffer.SetCurrentKey("Expense ID");
            ExistingBuffer.SetRange("Expense ID", ExpenseId);
            if not ExistingBuffer.IsEmpty() then
                exit(-1);
            ExistingArchive.SetCurrentKey("Expense ID");
            ExistingArchive.SetRange("Expense ID", ExpenseId);
            if not ExistingArchive.IsEmpty() then
                exit(-1);
        end;

        Buffer.Init();
        Buffer."Entry No." := 0;
        Buffer."Batch Code" := BatchCode;
        Buffer."Row No." := RowNo;
        Buffer."Expense Date" := ParseDate(GetField(LineFields, ColDate));
        Buffer."Receipt No." := CopyStr(GetField(LineFields, ColReceipt), 1, 20);
        Buffer."Expense Type" := ParseExpenseType(GetField(LineFields, ColExpenseType));
        Buffer.Amount := ParseDecimal(GetField(LineFields, ColAmount));
        Buffer."Currency Code" := CopyStr(GetField(LineFields, ColCurrency), 1, 10);
        Buffer."Source Description" := CopyStr(GetField(LineFields, ColSourceDesc), 1, 100);
        Buffer.Category := CopyStr(GetField(LineFields, ColCategory), 1, 100);
        Buffer.Owner := CopyStr(GetField(LineFields, ColOwner), 1, 100);
        Buffer.Note := CopyStr(StripLineBreaks(GetField(LineFields, ColNote)), 1, 250);
        Buffer.Team := CopyStr(GetField(LineFields, ColTeam), 1, 50);
        Buffer."Expense ID" := ExpenseId;
        Buffer."Receipt URL" := CopyStr(FirstUrl(GetField(LineFields, ColReceiptUrls)), 1, 250);
        Buffer."Project Code" := CopyStr(GetField(LineFields, ColProjectCode), 1, 20);
        Buffer."Project Name" := CopyStr(GetField(LineFields, ColProjectName), 1, 100);
        Buffer."Cost Type Code" := CopyStr(GetField(LineFields, ColCostTypeCode), 1, 20);
        Buffer."Cost Type Name" := CopyStr(GetField(LineFields, ColCostTypeName), 1, 100);
        Buffer."Pleo Vendor Code" := CopyStr(GetField(LineFields, ColVendorCode), 1, 20);
        Buffer."Pleo Vendor Name" := CopyStr(GetField(LineFields, ColVendorName), 1, 100);
        Buffer.Status := Buffer.Status::Pending;
        Buffer.Insert(true);
        exit(1);
    end;

    local procedure ResolveColumns(LineFields: List of [Text])
    var
        i: Integer;
        h: Text;
    begin
        for i := 1 to LineFields.Count() do begin
            h := NormalizeHeader(LineFields.Get(i));
            case h of
                'DATE':
                    ColDate := i;
                'RECEIPT':
                    ColReceipt := i;
                'EXPENSETYPE':
                    ColExpenseType := i;
                'AMOUNT':
                    ColAmount := i;
                'CURRENCY':
                    ColCurrency := i;
                'SOURCEDESCRIPTION':
                    ColSourceDesc := i;
                'CATEGORY':
                    ColCategory := i;
                'OWNER':
                    ColOwner := i;
                'NOTE':
                    ColNote := i;
                'TEAM':
                    ColTeam := i;
                'RECEIPTURLS':
                    ColReceiptUrls := i;
                'EXPENSEID':
                    ColExpenseId := i;
                'PROYECTO-NAME':
                    ColProjectName := i;
                'PROYECTO-CODE':
                    ColProjectCode := i;
                'TIPOGASTO-NAME':
                    ColCostTypeName := i;
                'TIPOGASTO-CODE':
                    ColCostTypeCode := i;
                'PROVEEDOR-NAME':
                    ColVendorName := i;
                'PROVEEDOR-CODE':
                    ColVendorCode := i;
            end;
        end;
    end;

    // Normaliza un título de cabecera: mayúsculas y solo A-Z, 0-9, punto, guion y %.
    // Así se eliminan espacios, BOM y cualquier carácter raro de codificación.
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

    // Divide una línea por ; respetando campos entrecomillados ("" = comilla escapada).
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
                    ';':
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

    local procedure ParseExpenseType(Value: Text): Enum "BeDyn Pleo Expense Type"
    begin
        case UpperCase(DelChr(Value, '=', ' ')) of
            'CARDPURCHASE':
                exit("BeDyn Pleo Expense Type"::"Card Purchase");
            'WALLETLOAD':
                exit("BeDyn Pleo Expense Type"::"Wallet Load");
            'CASHBACK':
                exit("BeDyn Pleo Expense Type"::Cashback);
        end;
        exit("BeDyn Pleo Expense Type"::Other);
    end;

    local procedure ParseDecimal(Txt: Text) Result: Decimal
    begin
        if Txt = '' then
            exit(0);
        Txt := Txt.Replace('.', '');
        Txt := Txt.Replace(',', '.');
        if not Evaluate(Result, Txt, 9) then
            Result := 0;
    end;

    local procedure ParseDate(Txt: Text) Result: Date
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
        if not Evaluate(DayPart, Parts.Get(1)) then
            exit(0D);
        if not Evaluate(MonthPart, Parts.Get(2)) then
            exit(0D);
        if not Evaluate(YearPart, Parts.Get(3)) then
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

    local procedure FirstUrl(Value: Text): Text
    var
        Parts: List of [Text];
    begin
        if Value = '' then
            exit('');
        Parts := Value.Split(',');
        exit(Parts.Get(1));
    end;
}
