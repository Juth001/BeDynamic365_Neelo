namespace BeDynamic.PleoImport;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Projects.Project.Job;

codeunit 82101 "BeDyn Pleo Validation"
{
    // Valida las líneas del buffer y resuelve proveedor BC, cuenta de gasto o
    // activo fijo (CAPEX) y valor de dimensión de proyecto. Deja cada línea en
    // estado Validada, Error u Omitida.

    var
        Setup: Record "BeDyn Pleo Setup";

    procedure ValidateBatch(BatchCode: Code[20])
    var
        Buffer: Record "BeDyn Pleo Import Buffer";
    begin
        Buffer.SetRange("Batch Code", BatchCode);
        ValidateLines(Buffer);
    end;

    procedure ValidateLines(var BufferParam: Record "BeDyn Pleo Import Buffer")
    var
        Buffer: Record "BeDyn Pleo Import Buffer";
    begin
        Setup.GetSetup();
        Buffer.Copy(BufferParam);
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::Pending, Buffer.Status::Error);
        if not Buffer.FindSet(true) then
            exit;
        repeat
            ValidateLine(Buffer);
        until Buffer.Next() = 0;
    end;

    local procedure ValidateLine(var Buffer: Record "BeDyn Pleo Import Buffer")
    var
        ErrText: Text;
        WalletSkipLbl: Label 'Recarga de monedero: omitida (activar en configuración para contabilizarla).';
        CashbackSkipLbl: Label 'Cashback: omitido (activar en configuración para contabilizarlo).';
        OtherSkipLbl: Label 'Tipo de movimiento no soportado.';
        ZeroSkipLbl: Label 'Importe cero.';
        NoReceiptWarnLbl: Label 'Falta el justificante: el gasto no tiene URL de recibo en Pleo.';
    begin
        Buffer."Error Message" := '';
        Buffer."Warning Message" := '';

        if Buffer.Amount = 0 then begin
            Buffer.SetSkippedState(ZeroSkipLbl);
            exit;
        end;

        case Buffer."Expense Type" of
            Buffer."Expense Type"::"Card Purchase":
                begin
                    ErrText := ValidateCardPurchase(Buffer);
                    if ErrText <> '' then begin
                        Buffer.SetErrorState(ErrText);
                        exit;
                    end;
                end;
            Buffer."Expense Type"::"Wallet Load":
                begin
                    if not Setup."Process Wallet Loads" then begin
                        Buffer.SetSkippedState(WalletSkipLbl);
                        exit;
                    end;
                    ErrText := ValidateWalletLoad(Buffer);
                    if ErrText <> '' then begin
                        Buffer.SetErrorState(ErrText);
                        exit;
                    end;
                end;
            Buffer."Expense Type"::Cashback:
                begin
                    if not Setup."Process Cashbacks" then begin
                        Buffer.SetSkippedState(CashbackSkipLbl);
                        exit;
                    end;
                    ErrText := ValidateCashback(Buffer);
                    if ErrText <> '' then begin
                        Buffer.SetErrorState(ErrText);
                        exit;
                    end;
                end;
            else begin
                Buffer.SetSkippedState(OtherSkipLbl);
                exit;
            end;
        end;

        // Avisos no bloqueantes: la línea queda validada pero marcada en amarillo.
        if (Buffer."Expense Type" = Buffer."Expense Type"::"Card Purchase") and (Buffer."Receipt URL" = '') then
            Buffer."Warning Message" := NoReceiptWarnLbl;

        Buffer.Status := Buffer.Status::Validated;
        Buffer.Modify(true);
    end;

    local procedure ValidateCardPurchase(var Buffer: Record "BeDyn Pleo Import Buffer") ErrText: Text
    var
        NoDateErr: Label 'La línea no tiene fecha.';
        NoReceiptErr: Label 'La línea no tiene nº de recibo Pleo.';
        CurrencyErr: Label 'Divisa %1 no soportada (solo EUR).', Comment = '%1 = código divisa';
        NoVATGroupErr: Label 'Falta el grupo IVA producto en la configuración de importación Pleo.';
        NoExtraAccErr: Label 'Falta la cuenta de gastos extraordinarios en la configuración de importación Pleo.';
        NoPleoBankErr: Label 'Falta el banco Pleo en la configuración.';
    begin
        if Buffer."Expense Date" = 0D then
            exit(NoDateErr);
        if Buffer."Receipt No." = '' then
            exit(NoReceiptErr);
        if (Buffer."Currency Code" <> '') and (Buffer."Currency Code" <> 'EUR') then
            exit(StrSubstNo(CurrencyErr, Buffer."Currency Code"));

        ApplyDefaultProject(Buffer);
        ResolvePurchaser(Buffer);

        // Gasto extraordinario: va por diario banco Pleo -> cuenta de gastos
        // extraordinarios, sin proveedor, sin IVA y sin factura.
        if Buffer.Extraordinary then begin
            Buffer."Mapped Vendor No." := '';
            Buffer."Fixed Asset No." := '';
            Buffer.CAPEX := false;
            Buffer."Job No." := '';
            Buffer."Job Task No." := '';
            Buffer."G/L Account No." := Setup."Extraord. Expense G/L Account";
            if Buffer."G/L Account No." = '' then
                exit(NoExtraAccErr);
            if Setup."Pleo Bank Account No." = '' then
                exit(NoPleoBankErr);
            exit(CheckProjectDimension(Buffer));
        end;

        if Setup."VAT Prod. Posting Group" = '' then
            exit(NoVATGroupErr);

        ErrText := ResolveVendor(Buffer);
        if ErrText <> '' then
            exit(ErrText);

        ErrText := ResolveAccountOrFixedAsset(Buffer);
        if ErrText <> '' then
            exit(ErrText);

        ErrText := ResolveJobTask(Buffer);
        if ErrText <> '' then
            exit(ErrText);

        ErrText := CheckProjectDimension(Buffer);
    end;

    local procedure ValidateWalletLoad(Buffer: Record "BeDyn Pleo Import Buffer"): Text
    var
        NoDateErr: Label 'La línea no tiene fecha.';
        NoPleoBankErr: Label 'Falta el banco Pleo en la configuración.';
        NoOriginBankErr: Label 'Falta el banco de origen de las recargas en la configuración.';
    begin
        if Buffer."Expense Date" = 0D then
            exit(NoDateErr);
        if Setup."Pleo Bank Account No." = '' then
            exit(NoPleoBankErr);
        if Setup."Wallet Origin Bank Account" = '' then
            exit(NoOriginBankErr);
    end;

    local procedure ValidateCashback(Buffer: Record "BeDyn Pleo Import Buffer"): Text
    var
        NoDateErr: Label 'La línea no tiene fecha.';
        NoPleoBankErr: Label 'Falta el banco Pleo en la configuración.';
        NoCashbackAccErr: Label 'Falta la cuenta de ingreso de cashback en la configuración.';
    begin
        if Buffer."Expense Date" = 0D then
            exit(NoDateErr);
        if Setup."Pleo Bank Account No." = '' then
            exit(NoPleoBankErr);
        if Setup."Cashback G/L Account No." = '' then
            exit(NoCashbackAccErr);
    end;

    local procedure ResolveVendor(var Buffer: Record "BeDyn Pleo Import Buffer"): Text
    var
        Mapping: Record "BeDyn Pleo Vendor Mapping";
        NoVendorErr: Label 'El código de proveedor Pleo %1 (%2) no tiene proveedor BC asignado y no hay proveedor genérico en la configuración.', Comment = '%1 = código Pleo, %2 = nombre Pleo';
    begin
        Buffer."Mapped Vendor No." := '';

        if Buffer."Pleo Vendor Code" <> '' then
            if Mapping.Get(Buffer."Pleo Vendor Code") then begin
                if Mapping."Vendor No." <> '' then begin
                    Buffer."Mapped Vendor No." := Mapping."Vendor No.";
                    exit('');
                end;
            end else
                if Setup."Auto Create Vendor Mapping" then begin
                    Mapping.Init();
                    Mapping."Pleo Code" := Buffer."Pleo Vendor Code";
                    Mapping."Pleo Name" := Buffer."Pleo Vendor Name";
                    Mapping.Insert(true);
                end;

        if Setup."Generic Vendor No." <> '' then begin
            Buffer."Mapped Vendor No." := Setup."Generic Vendor No.";
            exit('');
        end;

        exit(StrSubstNo(NoVendorErr, Buffer."Pleo Vendor Code", Buffer."Pleo Vendor Name"));
    end;

    // Propiedad predeterminada: si el gasto viene de Pleo sin proyecto informado,
    // se completa con el valor configurado. Afecta a la dimensión de propiedad y a
    // la resolución del activo fijo en CAPEX. Solo rellena si está vacío, para
    // respetar el proyecto real de Pleo cuando sí viene informado.
    local procedure ApplyDefaultProject(var Buffer: Record "BeDyn Pleo Import Buffer")
    var
        DimValue: Record "Dimension Value";
    begin
        if (Buffer."Project Code" <> '') or (Setup."Default Project Code" = '') then
            exit;
        Buffer."Project Code" := Setup."Default Project Code";
        if (Buffer."Project Name" = '') and (Setup."Project Dimension Code" <> '') then
            if DimValue.Get(Setup."Project Dimension Code", Setup."Default Project Code") then
                Buffer."Project Name" := CopyStr(DimValue.Name, 1, MaxStrLen(Buffer."Project Name"));
    end;

    // El comprador es opcional: si el empleado no está mapeado, la factura se crea
    // sin comprador (no se considera error de validación).
    // Aquí se resuelve también si el gasto es extraordinario: empleado marcado como
    // "No deducible" y gasto sin justificante (con justificante se trata normal).
    local procedure ResolvePurchaser(var Buffer: Record "BeDyn Pleo Import Buffer")
    var
        Mapping: Record "BeDyn Pleo Purchaser Mapping";
    begin
        Buffer."Purchaser Code" := '';
        Buffer.Extraordinary := false;
        if Buffer.Owner = '' then
            exit;

        if Mapping.Get(Buffer.Owner) then begin
            Buffer."Purchaser Code" := Mapping."Salesperson/Purch. Code";
            Buffer.Extraordinary := Mapping."Non-Deductible" and (Buffer."Receipt URL" = '');
            exit;
        end;

        if Setup."Auto Create Purchaser Mapping" then begin
            Mapping.Init();
            Mapping."Pleo Owner" := Buffer.Owner;
            Mapping.Insert(true);
        end;
    end;

    local procedure ResolveAccountOrFixedAsset(var Buffer: Record "BeDyn Pleo Import Buffer"): Text
    var
        ExpenseMap: Record "BeDyn Pleo Category Map";
        NoAccountErr: Label 'La categoría Pleo "%1" no tiene cuenta asignada y no hay cuenta por defecto en la configuración.', Comment = '%1 = categoría Pleo';
        NoCategoryErr: Label 'La línea no tiene categoría en Pleo y no hay cuenta por defecto en la configuración.';
    begin
        Buffer."G/L Account No." := '';
        Buffer."Fixed Asset No." := '';
        Buffer.CAPEX := false;

        // La categoría de Pleo (columna "Category") determina el destino contable
        // mediante el mapeo de categorías. Sin categoría no hay mapeo posible y la
        // línea va a la cuenta por defecto.
        if Buffer.Category <> '' then
            if ExpenseMap.Get(Buffer.Category) then begin
                // Categoría CAPEX: la línea va a un activo fijo determinado por la
                // propiedad (Proyecto de Pleo = ubicación del activo) y por la
                // clase/subclase del mapeo, si se han indicado.
                if ExpenseMap.CAPEX then begin
                    Buffer.CAPEX := true;
                    exit(ResolveFixedAsset(Buffer, ExpenseMap));
                end;
                if ExpenseMap."G/L Account No." <> '' then begin
                    Buffer."G/L Account No." := ExpenseMap."G/L Account No.";
                    exit('');
                end;
            end else
                if Setup."Auto Create Expense Map" then begin
                    ExpenseMap.Init();
                    ExpenseMap."Pleo Category" := Buffer.Category;
                    ExpenseMap.Insert(true);
                end;

        if Setup."Default G/L Account No." <> '' then begin
            Buffer."G/L Account No." := Setup."Default G/L Account No.";
            exit('');
        end;

        if Buffer.Category = '' then
            exit(NoCategoryErr);
        exit(StrSubstNo(NoAccountErr, Buffer.Category));
    end;

    local procedure ResolveFixedAsset(var Buffer: Record "BeDyn Pleo Import Buffer"; ExpenseMap: Record "BeDyn Pleo Category Map"): Text
    var
        FixedAsset: Record "Fixed Asset";
        FALocationCode: Code[10];
        NoProjectErr: Label 'La línea es CAPEX pero no tiene propiedad (Proyecto) en Pleo: no se puede determinar el activo fijo.';
        NoFAErr: Label 'No existe ningún activo fijo con ubicación %1 (activa la creación automática en configuración o créalo a mano).', Comment = '%1 = código propiedad';
        NoFAClassErr: Label 'No existe ningún activo fijo con ubicación %1 y clase/subclase %2 %3 (activa la creación automática en configuración o créalo a mano).', Comment = '%1 = código propiedad, %2 = clase, %3 = subclase';
        LocTooLongErr: Label 'El código de propiedad %1 supera los 10 caracteres de la ubicación de activo fijo, incluso quitando separadores. Acorta el código de proyecto en Pleo o asigna el activo a mano.', Comment = '%1 = código propiedad';
    begin
        if Buffer."Project Code" = '' then
            exit(NoProjectErr);

        FALocationCode := GetFALocationCode(Buffer."Project Code");
        if FALocationCode = '' then
            exit(StrSubstNo(LocTooLongErr, Buffer."Project Code"));

        EnsureFALocation(FALocationCode, Buffer."Project Name");

        FixedAsset.SetRange("FA Location Code", FALocationCode);
        FixedAsset.SetRange(Blocked, false);
        FixedAsset.SetRange(Inactive, false);
        // Si el mapeo indica clase/subclase, el activo debe coincidir: cada propiedad
        // puede tener un activo distinto por clase (p.ej. obra vs mobiliario).
        if ExpenseMap."FA Class Code" <> '' then
            FixedAsset.SetRange("FA Class Code", ExpenseMap."FA Class Code");
        if ExpenseMap."FA Subclass Code" <> '' then
            FixedAsset.SetRange("FA Subclass Code", ExpenseMap."FA Subclass Code");
        if FixedAsset.FindFirst() then begin
            Buffer."Fixed Asset No." := FixedAsset."No.";
            exit('');
        end;

        if not Setup."Auto Create Fixed Assets" then begin
            if (ExpenseMap."FA Class Code" <> '') or (ExpenseMap."FA Subclass Code" <> '') then
                exit(StrSubstNo(NoFAClassErr, Buffer."Project Code", ExpenseMap."FA Class Code", ExpenseMap."FA Subclass Code"));
            exit(StrSubstNo(NoFAErr, Buffer."Project Code"));
        end;

        CreateFixedAsset(FixedAsset, Buffer, ExpenseMap, FALocationCode);
        Buffer."Fixed Asset No." := FixedAsset."No.";
        exit('');
    end;

    // La ubicación del activo fijo es Code[10] pero el código de propiedad de Pleo
    // puede ser más largo (p.ej. ES-01-02-024). Si no cabe tal cual, se compacta
    // quitando los separadores (ES-01-02-024 -> ES0102024), que conserva los dígitos
    // que distinguen unas propiedades de otras. Si ni compactado cabe, devuelve ''
    // y la línea queda en error de validación (nunca truncar: dos propiedades
    // distintas acabarían compartiendo activo).
    local procedure GetFALocationCode(ProjectCode: Code[20]): Code[10]
    var
        FALocation: Record "FA Location";
        Builder: TextBuilder;
        i: Integer;
        Ch: Char;
        Compact: Text;
    begin
        if StrLen(ProjectCode) <= MaxStrLen(FALocation.Code) then
            exit(CopyStr(ProjectCode, 1, MaxStrLen(FALocation.Code)));

        for i := 1 to StrLen(ProjectCode) do begin
            Ch := ProjectCode[i];
            if ((Ch >= 'A') and (Ch <= 'Z')) or ((Ch >= '0') and (Ch <= '9')) then
                Builder.Append(Ch);
        end;
        Compact := Builder.ToText();
        if StrLen(Compact) <= MaxStrLen(FALocation.Code) then
            exit(CopyStr(Compact, 1, MaxStrLen(FALocation.Code)));
        exit('');
    end;

    local procedure EnsureFALocation(LocationCode: Code[10]; LocationName: Text[100])
    var
        FALocation: Record "FA Location";
    begin
        if FALocation.Get(LocationCode) then
            exit;
        FALocation.Init();
        FALocation.Code := LocationCode;
        FALocation.Name := CopyStr(LocationName, 1, MaxStrLen(FALocation.Name));
        FALocation.Insert(true);
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset"; Buffer: Record "BeDyn Pleo Import Buffer"; ExpenseMap: Record "BeDyn Pleo Category Map"; FALocationCode: Code[10])
    var
        FADeprBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FASubclass: Record "FA Subclass";
        DeprBookCode: Code[10];
        FAPostingGroup: Code[20];
        ClassCode: Code[10];
        SubclassCode: Code[10];
        DescText: Text;
    begin
        DescText := Buffer."Project Name";
        if DescText = '' then
            DescText := Buffer."Project Code";

        // Clase/subclase del mapeo de la categoría; la subclase del setup solo
        // aplica si el mapeo no indica nada (comportamiento anterior).
        ClassCode := ExpenseMap."FA Class Code";
        SubclassCode := ExpenseMap."FA Subclass Code";
        if (ClassCode = '') and (SubclassCode = '') then
            SubclassCode := Setup."FA Subclass Code";

        FixedAsset.Init();
        FixedAsset."No." := '';
        FixedAsset.Insert(true);
        FixedAsset.Validate(Description, CopyStr(DescText, 1, MaxStrLen(FixedAsset.Description)));
        if ClassCode <> '' then
            FixedAsset.Validate("FA Class Code", ClassCode);
        if SubclassCode <> '' then
            FixedAsset.Validate("FA Subclass Code", SubclassCode);
        FixedAsset.Validate("FA Location Code", FALocationCode);
        FixedAsset.Modify(true);

        // Libro de amortización: el del setup o, en su defecto, el libro por defecto de BC.
        DeprBookCode := Setup."FA Depreciation Book Code";
        if DeprBookCode = '' then
            if FASetup.Get() then
                DeprBookCode := FASetup."Default Depr. Book";
        if DeprBookCode = '' then
            exit;

        FAPostingGroup := Setup."FA Posting Group";
        if (FAPostingGroup = '') and (SubclassCode <> '') then
            if FASubclass.Get(SubclassCode) then
                FAPostingGroup := FASubclass."Default FA Posting Group";

        FADeprBook.Init();
        FADeprBook."FA No." := FixedAsset."No.";
        FADeprBook."Depreciation Book Code" := DeprBookCode;
        FADeprBook.Insert(true);
        if FAPostingGroup <> '' then
            FADeprBook.Validate("FA Posting Group", FAPostingGroup);
        FADeprBook.Validate("Depreciation Starting Date", Buffer."Expense Date");
        FADeprBook.Modify(true);
    end;

    // Imputación a proyecto: si la propiedad (Proyecto de Pleo) tiene un proyecto
    // BC con su mismo código (los crea el asistente de propiedades) y el mapeo de
    // la categoría de Pleo indica una tarea, el gasto se repercutirá a esa tarea
    // del proyecto. Sin proyecto BC o sin tarea en el mapeo, la línea va sin
    // imputación (no es error). Las líneas CAPEX van a activo fijo y no admiten
    // proyecto en la línea de compra.
    local procedure ResolveJobTask(var Buffer: Record "BeDyn Pleo Import Buffer"): Text
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        ExpenseMap: Record "BeDyn Pleo Category Map";
        BlockedErr: Label 'El proyecto %1 de la propiedad está bloqueado o no está abierto: desbloquéalo o quita la tarea del mapeo de la categoría.', Comment = '%1 = proyecto';
        NoTaskErr: Label 'El proyecto %1 no tiene la tarea %2 (asignada a la categoría "%3" en el mapeo): créala en el proyecto o quita la tarea del mapeo.', Comment = '%1 = proyecto, %2 = tarea, %3 = categoría Pleo';
        NotPostingErr: Label 'La tarea %1 del proyecto %2 no es de tipo Registro: no admite imputación de gastos.', Comment = '%1 = tarea, %2 = proyecto';
    begin
        Buffer."Job No." := '';
        Buffer."Job Task No." := '';

        if Buffer.CAPEX then
            exit('');
        if (Buffer."Project Code" = '') or (Buffer.Category = '') then
            exit('');
        if not ExpenseMap.Get(Buffer.Category) then
            exit('');
        if ExpenseMap."Job Task No." = '' then
            exit('');
        if not Job.Get(Buffer."Project Code") then
            exit('');
        if (Job.Blocked <> Job.Blocked::" ") or (Job.Status <> Job.Status::Open) then
            exit(StrSubstNo(BlockedErr, Job."No."));
        if not JobTask.Get(Job."No.", ExpenseMap."Job Task No.") then
            exit(StrSubstNo(NoTaskErr, Job."No.", ExpenseMap."Job Task No.", Buffer.Category));
        if JobTask."Job Task Type" <> JobTask."Job Task Type"::Posting then
            exit(StrSubstNo(NotPostingErr, JobTask."Job Task No.", Job."No."));

        Buffer."Job No." := Job."No.";
        Buffer."Job Task No." := ExpenseMap."Job Task No.";
        exit('');
    end;

    local procedure CheckProjectDimension(Buffer: Record "BeDyn Pleo Import Buffer"): Text
    var
        DimValue: Record "Dimension Value";
        NoDimValueErr: Label 'El valor %1 no existe en la dimensión %2 (activa la creación automática en configuración o créalo a mano).', Comment = '%1 = valor, %2 = dimensión';
    begin
        if (Setup."Project Dimension Code" = '') or (Buffer."Project Code" = '') then
            exit('');

        if DimValue.Get(Setup."Project Dimension Code", Buffer."Project Code") then
            exit('');

        if not Setup."Auto Create Dim. Values" then
            exit(StrSubstNo(NoDimValueErr, Buffer."Project Code", Setup."Project Dimension Code"));

        DimValue.Init();
        DimValue."Dimension Code" := Setup."Project Dimension Code";
        DimValue.Code := Buffer."Project Code";
        DimValue.Name := CopyStr(Buffer."Project Name", 1, MaxStrLen(DimValue.Name));
        DimValue.Insert(true);
        exit('');
    end;
}
