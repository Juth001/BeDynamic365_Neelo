namespace Neelo.RecurringInvoicing;

/// <summary>
/// Imports the CSV file into the staging buffer.
///
/// Standard CSV structure (confirmed with the real template "Facturación Konserta.csv"):
///   1 BILLING CODE (matched against the customer billing configuration, e.g. REC)
///   2 Tax ID  3 POSTING DATE  4 EXTERNAL DOC. NO.  5 CONCEPT
///   6 AMOUNT  7 BC ID (customer no., tie-breaker for duplicated Tax IDs)
///   8 VAT PROD. POSTING GROUP (optional; overrides the one from the item/account)
///   (+ trailing empty columns)
///
/// Individuals CSV structure (template "ALQ Importacion particulares"): the external
/// doc. no. column carries the property instead, which is invoiced as the item of the
/// line, and three columns are added — the room (item variant), inserted before the
/// concept, and the business line (dimension value) at the end:
///   1 BILLING CODE  2 Tax ID (may be empty; the customer is then resolved by BC ID)
///   3 POSTING DATE  4 PROPERTY (item no.)  5 ROOM (item variant)  6 CONCEPT
///   7 AMOUNT  8 BC ID  9 VAT PROD. POSTING GROUP (optional)
///   10 BUSINESS LINE (optional; value of the dimension set up in
///   "Business Line Dimension Code", stamped on the header and lines)
///   11 CHANNEL (optional; value of the dimension set up in
///   "Channel Dimension Code", stamped on the header and lines)
///   12 UNIT (optional; value of the dimension set up in
///   "Unit Dimension Code", stamped on the header and lines)
///
/// The parser handles: quoted fields with ", the ; separator inside quotes, escaped
/// quotes "", multi-line concepts (a record spanning several physical lines) and
/// amounts in Spanish format (1,234.56 written as 1.234,56).
/// </summary>
codeunit 81009 "BeDyn Import Mgt."
{
    var
        Setup: Record "BeDyn Recurring Inv. Setup";
        SepChar: Char;
        BatchCodeGlobal: Code[20];
        RecordIndex: Integer;
        ImportedCount: Integer;
        IndividualsLayout: Boolean;
        SetupNotActiveErr: Label 'The recurring invoicing setup is not active.';
        NothingImportedMsg: Label 'No lines were imported from the file.';
        ImportedMsg: Label '%1 lines imported into batch %2.', Comment = '%1 = line count, %2 = batch code';
        NonNumericAmountErr: Label 'Non-numeric amount: "%1".', Comment = '%1 = amount read from CSV';
        InvalidDateErr: Label 'Invalid posting date: "%1".', Comment = '%1 = date read from CSV';
        UploadDialogTxt: Label 'Select the CSV';
        FileFilterTxt: Label 'CSV files (*.csv)|*.csv|All files (*.*)|*.*';

    /// <summary>
    /// Same upload/parse flow as ImportCSV but mapping the columns of the individuals
    /// template layout (property, room and business line).
    /// </summary>
    procedure ImportIndividualsCSV(): Code[20]
    begin
        IndividualsLayout := true;
        exit(ImportCSV());
    end;

    /// <summary>
    /// Uploads a CSV, parses it according to the setup and inserts the lines into the buffer.
    /// Returns the generated batch code (empty if cancelled).
    /// </summary>
    procedure ImportCSV(): Code[20]
    var
        FileName: Text;
        InStr: InStream;
        Content: Text;
    begin
        Setup.GetSetup();
        if not Setup.Active then
            Error(SetupNotActiveErr);

        if not UploadIntoStream(UploadDialogTxt, '', FileFilterTxt, FileName, InStr) then
            exit('');

        Content := ReadAllText(InStr);
        if Content = '' then begin
            Message(NothingImportedMsg);
            exit('');
        end;

        BatchCodeGlobal := GenerateBatchCode();
        SepChar := GetSeparator();
        RecordIndex := 0;
        ImportedCount := 0;

        ParseContent(Content);

        if ImportedCount = 0 then begin
            Message(NothingImportedMsg);
            exit('');
        end;

        Message(ImportedMsg, ImportedCount, BatchCodeGlobal);
        exit(BatchCodeGlobal);
    end;

    /// <summary>
    /// Moves the processed lines (posted or ignored) within the given filters to the
    /// archive table, stamping when and by whom. Returns the number of archived lines.
    /// </summary>
    procedure ArchiveProcessed(var BufferParam: Record "BeDyn Invoice Import Buffer") Count: Integer
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        Archive: Record "BeDyn Invoice Import Archive";
    begin
        Buffer.Copy(BufferParam);
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::Posted, Buffer.Status::Ignored);
        if not Buffer.FindSet() then
            exit(0);
        repeat
            Archive.Init();
            Archive.TransferFields(Buffer);
            Archive."Archived At" := CurrentDateTime();
            Archive."Archived By" := CopyStr(UserId(), 1, MaxStrLen(Archive."Archived By"));
            Archive.Insert();
            Count += 1;
        until Buffer.Next() = 0;
        Buffer.DeleteAll();
    end;

    /// <summary>Reads the whole InStream into text, normalizing line breaks to LF.</summary>
    local procedure ReadAllText(var InStr: InStream): Text
    var
        Builder: TextBuilder;
        LineText: Text;
        NlChar: Char;
    begin
        NlChar := 10; // LF
        while not InStr.EOS() do begin
            InStr.ReadText(LineText);
            Builder.Append(LineText);
            Builder.Append(NlChar);
        end;
        exit(Builder.ToText());
    end;

    /// <summary>
    /// State machine that parses the whole CSV content and, for each record (which may
    /// span several physical lines when quotes are used), inserts a buffer line.
    /// </summary>
    local procedure ParseContent(Content: Text)
    var
        Fields: List of [Text];
        CurrentField: Text;
        i: Integer;
        Len: Integer;
        Ch: Char;
        QuoteChar: Char;
        NlChar: Char;
        InQuotes: Boolean;
    begin
        QuoteChar := '"';
        NlChar := 10;
        Len := StrLen(Content);
        i := 1;
        while i <= Len do begin
            Ch := Content[i];
            if InQuotes then
                case Ch of
                    QuoteChar:
                        if (i < Len) and (Content[i + 1] = QuoteChar) then begin
                            CurrentField += '"';
                            i += 1; // escaped quote ""
                        end else
                            InQuotes := false;
                    NlChar:
                        CurrentField += ' '; // multi-line concept -> space
                    else
                        CurrentField += Ch;
                end
            else
                if (Ch = QuoteChar) and (CurrentField = '') then
                    InQuotes := true
                else
                    if Ch = SepChar then begin
                        Fields.Add(CurrentField);
                        CurrentField := '';
                    end else
                        if Ch = NlChar then begin
                            Fields.Add(CurrentField);
                            CurrentField := '';
                            ProcessRecord(Fields);
                            Clear(Fields);
                        end else
                            CurrentField += Ch;
            i += 1;
        end;

        // Final record without a trailing line break.
        if (CurrentField <> '') or (Fields.Count() > 0) then begin
            Fields.Add(CurrentField);
            ProcessRecord(Fields);
        end;
    end;

    local procedure ProcessRecord(Fields: List of [Text])
    begin
        RecordIndex += 1;

        // Skip the header row: when configured and, in the individuals layout, also by
        // detection (the template always ships with a header, whose date and amount
        // columns are titles), so it does not depend on the "Has Header" setting.
        if (RecordIndex = 1) and (Setup."Has Header" or IsHeaderRecord(Fields)) then
            exit;

        if RecordIsEmpty(Fields) then
            exit;

        if InsertBufferLine(Fields) then
            ImportedCount += 1;
    end;

    /// <summary>
    /// Individuals layout: the first record is the header when neither its date nor its
    /// amount column can be parsed (both carry titles). A data row with a bad date but a
    /// numeric amount is not a header: it is imported and flagged with the date error.
    /// </summary>
    local procedure IsHeaderRecord(Fields: List of [Text]): Boolean
    var
        DateTxt: Text;
        AmountTxt: Text;
        ParsedDate: Date;
        ParsedAmount: Decimal;
    begin
        if not IndividualsLayout then
            exit(false);
        DateTxt := GetField(Fields, 3);
        AmountTxt := GetField(Fields, 7);
        if (DateTxt = '') or (AmountTxt = '') then
            exit(false);
        exit((not TryParseDate(DateTxt, ParsedDate)) and (not TryParseDecimal(AmountTxt, ParsedAmount)));
    end;

    local procedure RecordIsEmpty(Fields: List of [Text]) IsEmpty: Boolean
    var
        FieldText: Text;
    begin
        IsEmpty := true;
        foreach FieldText in Fields do
            if DelChr(FieldText, '<>', ' ') <> '' then
                exit(false);
    end;

    local procedure InsertBufferLine(Fields: List of [Text]): Boolean
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        AmountTxt: Text;
        DateTxt: Text;
        ParsedAmount: Decimal;
        ParsedDate: Date;
        ParseError: Text;
    begin
        DateTxt := GetField(Fields, 3);
        if IndividualsLayout then
            AmountTxt := GetField(Fields, 7)
        else
            AmountTxt := GetField(Fields, 6);

        Buffer.Init();
        Buffer."Import Batch Code" := BatchCodeGlobal;
        Buffer."Line No." := RecordIndex;
        Buffer."Billing Code" := CopyStr(UpperCase(GetField(Fields, 1)), 1, MaxStrLen(Buffer."Billing Code"));
        Buffer."VAT Registration No." := CopyStr(GetField(Fields, 2), 1, MaxStrLen(Buffer."VAT Registration No."));
        if IndividualsLayout then begin
            // The property doubles as the external document no. of the header.
            Buffer."Property Code" := CopyStr(UpperCase(GetField(Fields, 4)), 1, MaxStrLen(Buffer."Property Code"));
            Buffer."External Document No." := Buffer."Property Code";
            Buffer."Variant Code" := CopyStr(UpperCase(GetField(Fields, 5)), 1, MaxStrLen(Buffer."Variant Code"));
            Buffer.Description := CopyStr(GetField(Fields, 6), 1, MaxStrLen(Buffer.Description));
            Buffer."BC Customer No." := CopyStr(UpperCase(GetField(Fields, 8)), 1, MaxStrLen(Buffer."BC Customer No."));
            Buffer."VAT Prod. Posting Group" := CopyStr(UpperCase(GetField(Fields, 9)), 1, MaxStrLen(Buffer."VAT Prod. Posting Group"));
            Buffer."Business Line Code" := CopyStr(UpperCase(GetField(Fields, 10)), 1, MaxStrLen(Buffer."Business Line Code"));
            Buffer."Channel Code" := CopyStr(UpperCase(GetField(Fields, 11)), 1, MaxStrLen(Buffer."Channel Code"));
            Buffer."Unit Code" := CopyStr(UpperCase(GetField(Fields, 12)), 1, MaxStrLen(Buffer."Unit Code"));
        end else begin
            Buffer."External Document No." := CopyStr(GetField(Fields, 4), 1, MaxStrLen(Buffer."External Document No."));
            Buffer.Description := CopyStr(GetField(Fields, 5), 1, MaxStrLen(Buffer.Description));
            Buffer."BC Customer No." := CopyStr(GetField(Fields, 7), 1, MaxStrLen(Buffer."BC Customer No."));
            Buffer."VAT Prod. Posting Group" := CopyStr(UpperCase(GetField(Fields, 8)), 1, MaxStrLen(Buffer."VAT Prod. Posting Group"));
        end;
        Buffer.Status := Buffer.Status::Pending;

        // Posting date. An empty date is left blank (validation may flag it); a present but
        // unparseable date is a parse error.
        if DateTxt <> '' then
            if TryParseDate(DateTxt, ParsedDate) then
                Buffer."Posting Date" := ParsedDate
            else begin
                Buffer.Status := Buffer.Status::Error;
                ParseError := StrSubstNo(InvalidDateErr, DateTxt);
            end;

        // Amount. An empty amount is treated as 0 (validation flags it, not a parse error).
        if AmountTxt = '' then
            Buffer.Amount := 0
        else
            if TryParseDecimal(AmountTxt, ParsedAmount) then
                Buffer.Amount := ParsedAmount
            else begin
                Buffer.Status := Buffer.Status::Error;
                if ParseError <> '' then
                    ParseError += ' ';
                ParseError += StrSubstNo(NonNumericAmountErr, AmountTxt);
            end;

        Buffer."Error Message" := CopyStr(ParseError, 1, MaxStrLen(Buffer."Error Message"));
        Buffer.Insert(true);
        exit(true);
    end;

    /// <summary>Returns field number Index (1-based) from the list, already trimmed.</summary>
    local procedure GetField(Fields: List of [Text]; Index: Integer): Text
    begin
        if Index <= Fields.Count() then
            exit(DelChr(Fields.Get(Index), '<>', ' '));
        exit('');
    end;

    /// <summary>
    /// Converts an amount in Spanish format (1.234,56) or English format (1234.56) to Decimal.
    /// Rule: if a comma is present, the comma is the decimal separator and dots are thousands.
    /// If only dots are present and the last group has 3 digits, it is treated as thousands.
    /// </summary>
    [TryFunction]
    local procedure TryParseDecimal(Input: Text; var Result: Decimal)
    var
        LastDot: Integer;
        LastComma: Integer;
    begin
        Input := DelChr(Input, '<>', ' ');
        LastDot := Input.LastIndexOf('.');
        LastComma := Input.LastIndexOf(',');

        if LastComma > 0 then begin
            // Comma = decimal separator; dots = thousands.
            Input := DelChr(Input, '=', '.');
            Input := Input.Replace(',', '.');
        end else
            if LastDot > 0 then
                // No comma: if the last group after the dot has 3 digits, it is a thousands separator.
                if (StrLen(Input) - LastDot) = 3 then
                    Input := DelChr(Input, '=', '.');
        // Otherwise the dot is kept as the decimal separator.

        Evaluate(Result, Input, 9);
    end;

    /// <summary>
    /// Parses a date in Spanish day-first format (dd/mm/yyyy or dd-mm-yyyy, also with 2-digit
    /// year) regardless of the regional settings, by splitting it into its parts.
    /// </summary>
    [TryFunction]
    local procedure TryParseDate(Input: Text; var Result: Date)
    var
        Parts: List of [Text];
        Normalized: Text;
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        Normalized := DelChr(Input, '<>', ' ');
        Normalized := Normalized.Replace('-', '/').Replace('.', '/');
        Parts := Normalized.Split('/');
        if Parts.Count() <> 3 then
            Error(''); // makes the TryFunction fail

        Evaluate(Day, Parts.Get(1));
        Evaluate(Month, Parts.Get(2));
        Evaluate(Year, Parts.Get(3));
        if Year < 100 then
            Year += 2000;

        Result := DMY2Date(Day, Month, Year);
    end;

    local procedure GetSeparator(): Char
    begin
        if Setup."CSV Separator" <> '' then
            exit(Setup."CSV Separator"[1]);
        exit(';');
    end;

    /// <summary>Generates a unique batch code based on the current date/time.</summary>
    local procedure GenerateBatchCode(): Code[20]
    begin
        exit(CopyStr('IMP' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20));
    end;
}
