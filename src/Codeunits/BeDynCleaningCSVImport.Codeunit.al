namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 82700 "BeDyn Cleaning CSV Import"
{
    // Importa el fichero mensual de servicios de un proveedor de limpieza al staging.
    //
    // Formato del fichero (separador ; · decimal coma · fechas d/M/yyyy), una fila
    // por servicio prestado:
    //   1 fecha  2 propiedad (código)  3 servicio  4 cantidad  5 coste unidad
    //   6 total servicio  7 proveedor (opcional)
    //   8 factura compra a reclasificar (opcional)
    // La primera fila es la cabecera y se ignora sola (su columna de fecha no es una
    // fecha), igual que cualquier fila vacía. El código de servicio se normaliza
    // (mayúsculas, sin acentos: LAVANDERÍA -> LAVANDERIA) y debe existir en el
    // catálogo de servicios del proveedor; si no existe, la línea queda en error al
    // validar. La columna proveedor permite ficheros con servicios de varios
    // proveedores: si viene vacía, la fila se importa con el proveedor elegido al
    // iniciar la importación. La columna factura trae ya asignada la factura de
    // compra registrada que se reclasificará; si viene vacía, la factura deberá
    // asignarse en la hoja antes de validar (la validación exige factura). Los
    // importes son SIN IVA.

    var
        ImportedCount: Integer;
        SkippedCount: Integer;

    procedure ImportCSV(): Code[20]
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        FileInStr: InStream;
        OutStr: OutStream;
        BatchCode: Code[20];
        VendorNo: Code[20];
        FileName: Text;
        Line: Text;
        RowNo: Integer;
        FileEncoding: TextEncoding;
        UploadDialogTxt: Label 'Selecciona el CSV del proveedor de limpieza';
        FileFilterTxt: Label 'Ficheros CSV (*.csv)|*.csv|Todos los ficheros (*.*)|*.*';
        EmptyErr: Label 'El fichero está vacío.';
        NothingImportedMsg: Label 'No se ha importado ninguna línea del fichero.';
        ImportedMsg: Label '%1 líneas de servicio importadas en el lote %2 (%3 filas ignoradas).', Comment = '%1 = líneas, %2 = lote, %3 = filas ignoradas';
    begin
        PropertySetup.GetInstance();

        VendorNo := GetImportVendor(PropertySetup);
        if VendorNo = '' then
            exit('');
        CheckCatalogExists(VendorNo);

        if not UploadIntoStream(UploadDialogTxt, '', FileFilterTxt, FileName, FileInStr) then
            exit('');
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, FileInStr);
        if not TempBlob.HasValue() then
            Error(EmptyErr);

        FileEncoding := DetectEncoding(TempBlob);
        TempBlob.CreateInStream(InStr, FileEncoding);

        BatchCode := GenerateBatchCode();
        ImportedCount := 0;
        SkippedCount := 0;
        RowNo := 0;
        while not InStr.EOS() do begin
            ReadLogicalLine(InStr, Line);
            RowNo += 1;
            if DelChr(Line, '=', ';') <> '' then
                ProcessRow(Line, RowNo, BatchCode, VendorNo);
        end;

        if ImportedCount = 0 then begin
            Message(NothingImportedMsg);
            exit('');
        end;
        Message(ImportedMsg, ImportedCount, BatchCode, SkippedCount);
        exit(BatchCode);
    end;

    // El fichero pertenece a un proveedor: se propone el habitual de la
    // configuración y, si no hay o no se confirma, se elige de la lista.
    local procedure GetImportVendor(PropertySetup: Record "BeDyn Property Mgt. Setup"): Code[20]
    var
        Vendor: Record Vendor;
        DefaultVendorQst: Label '¿Importar el fichero como proveedor %1 %2?', Comment = '%1 = código, %2 = nombre';
    begin
        if PropertySetup."Cleaning Vendor No." <> '' then
            if Vendor.Get(PropertySetup."Cleaning Vendor No.") then
                if Confirm(DefaultVendorQst, true, Vendor."No.", Vendor.Name) then
                    exit(Vendor."No.");

        Vendor.Reset();
        if Page.RunModal(Page::"Vendor List", Vendor) = Action::LookupOK then
            exit(Vendor."No.");
        exit('');
    end;

    local procedure CheckCatalogExists(VendorNo: Code[20])
    var
        CleaningService: Record "BeDyn Cleaning Service";
        NoCatalogErr: Label 'El proveedor %1 no tiene servicios activos en el catálogo de servicios de limpieza. Configura el catálogo antes de importar.', Comment = '%1 = proveedor';
    begin
        CleaningService.SetRange("Vendor No.", VendorNo);
        CleaningService.SetRange(Blocked, false);
        if CleaningService.IsEmpty() then
            Error(NoCatalogErr, VendorNo);
    end;

    local procedure ProcessRow(Line: Text; RowNo: Integer; BatchCode: Code[20]; VendorNo: Code[20])
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
        LineFields: List of [Text];
        ServiceDate: Date;
        Qty: Decimal;
        UnitCost: Decimal;
        Amt: Decimal;
        LineVendorNo: Code[20];
        RowWarning: Text;
        TotalMismatchLbl: Label 'El total de la fila (%1) no cuadra con cantidad × coste unidad (%2).', Comment = '%1 = total de la fila, %2 = cantidad por coste unidad';
    begin
        SplitCsvLine(Line, LineFields);

        ServiceDate := ParseDate(GetRaw(LineFields, 1));
        if ServiceDate = 0D then begin
            SkippedCount += 1; // cabecera y filas sin fecha
            exit;
        end;

        Qty := ParseDecimal(GetRaw(LineFields, 4));
        UnitCost := ParseDecimal(GetRaw(LineFields, 5));
        Amt := ParseDecimal(GetRaw(LineFields, 6));
        if (Qty = 0) and (Amt = 0) then begin
            SkippedCount += 1;
            exit;
        end;

        // Coherencia interna de la fila: total = cantidad × coste unidad. El coste
        // unidad del fichero es informativo; el precio que valida es el pactado
        // (catálogo o precio por propiedad).
        if (UnitCost <> 0) and (Abs(Amt - Round(Qty * UnitCost, 0.01)) > 0.02) then
            RowWarning := StrSubstNo(TotalMismatchLbl, Format(Amt), Format(Round(Qty * UnitCost, 0.01)));

        // Proveedor de la fila: el de la columna 7 o, si viene vacía, el elegido
        // al iniciar la importación.
        LineVendorNo := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 7), '<>', ' ')), 1, MaxStrLen(ImportLine."Vendor No."));
        if LineVendorNo = '' then
            LineVendorNo := VendorNo;

        ImportLine.Init();
        ImportLine."Entry No." := 0;
        ImportLine."Batch Code" := BatchCode;
        ImportLine."Row No." := RowNo;
        ImportLine."Service Date" := ServiceDate;
        ImportLine."Vendor No." := LineVendorNo;
        ImportLine."Service Code" := CopyStr(NormalizeServiceCode(GetRaw(LineFields, 3)), 1, MaxStrLen(ImportLine."Service Code"));
        ImportLine."Property Code" := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 2), '<>', ' ')), 1, MaxStrLen(ImportLine."Property Code"));
        ImportLine.Quantity := Qty;
        ImportLine.Amount := Amt;
        ImportLine."Invoice No." := CopyStr(UpperCase(DelChr(GetRaw(LineFields, 8), '<>', ' ')), 1, MaxStrLen(ImportLine."Invoice No."));
        ImportLine."Warning Message" := CopyStr(RowWarning, 1, MaxStrLen(ImportLine."Warning Message"));
        ImportLine.Status := ImportLine.Status::Pending;
        ImportLine.Insert(true);
        ImportedCount += 1;
    end;

    // Mayúsculas, sin espacios y sin acentos, para que el código del fichero
    // (p. ej. LAVANDERÍA) case con el código del catálogo (LAVANDERIA).
    local procedure NormalizeServiceCode(Txt: Text): Text
    begin
        Txt := UpperCase(DelChr(Txt, '<>', ' '));
        exit(ConvertStr(Txt, 'ÁÀÂÄÉÈÊËÍÌÎÏÓÒÔÖÚÙÛÜ', 'AAAAEEEEIIIIOOOOUUUU'));
    end;

    local procedure GetRaw(LineFields: List of [Text]; Pos: Integer): Text
    begin
        if (Pos < 1) or (Pos > LineFields.Count()) then
            exit('');
        exit(LineFields.Get(Pos));
    end;

    // ============================ PARSEO ============================

    // Importes en formato español, tolerando símbolo de moneda: se conservan solo
    // dígitos y separadores y se convierte 1.234,56 -> 1234.56.
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
        exit(CopyStr('LIMP' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20));
    end;

    // ============================ LECTURA CSV ============================

    // Lee una línea lógica: si un campo entrecomillado contiene saltos de línea,
    // une las líneas físicas hasta cerrar las comillas.
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
