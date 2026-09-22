namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using BeDynamic.PropertyWizard;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Security.User;

codeunit 82701 "BeDyn Cleaning Validation"
{
    // Valida las líneas de staging: resuelve el proyecto desde la propiedad, y la
    // tarea estándar, la cuenta de gasto y el precio pactado desde el catálogo de
    // servicios del proveedor (con precios negociados por propiedad como
    // excepción). Deja cada línea en estado Validada o Error.

    var
        // Margen fijo para el redondeo a céntimos de cada fila del proveedor
        // (cantidad × precio se redondea a 2 decimales en el fichero).
        LineRoundingTolerance: Decimal;

    procedure ValidateLines(var ImportLineParam: Record "BeDyn Cleaning Import Line")
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
        ValidatedCount: Integer;
        ErrorCount: Integer;
        NothingMsg: Label 'No hay líneas pendientes de validar en la selección.';
        DoneMsg: Label 'Validación terminada: %1 líneas validadas, %2 con error.', Comment = '%1, %2 = contadores';
    begin
        LineRoundingTolerance := 0.02;

        ImportLine.Copy(ImportLineParam);
        ImportLine.SetFilter(Status, '%1|%2', ImportLine.Status::Pending, ImportLine.Status::Error);
        if not ImportLine.FindSet(true) then begin
            Message(NothingMsg);
            exit;
        end;
        repeat
            if ValidateLine(ImportLine) then
                ValidatedCount += 1
            else
                ErrorCount += 1;
        until ImportLine.Next() = 0;
        Message(DoneMsg, ValidatedCount, ErrorCount);
    end;

    local procedure ValidateLine(var ImportLine: Record "BeDyn Cleaning Import Line"): Boolean
    var
        CleaningService: Record "BeDyn Cleaning Service";
        ErrText: Text;
    begin
        ImportLine."Error Message" := '';

        ErrText := GetCatalogService(ImportLine, CleaningService);
        if ErrText = '' then
            ErrText := CheckPostingDate(ImportLine);
        if ErrText = '' then
            ErrText := ResolveJob(ImportLine);
        if ErrText = '' then
            ErrText := ResolveAccountAndTask(ImportLine, CleaningService);
        if ErrText = '' then
            ErrText := CheckAgreedPrice(ImportLine, CleaningService);
        if ErrText = '' then
            ErrText := CheckAssignedInvoice(ImportLine);

        if ErrText <> '' then begin
            ImportLine.SetErrorState(ErrText);
            exit(false);
        end;

        ImportLine.Status := ImportLine.Status::Validated;
        ImportLine.Modify(true);
        exit(true);
    end;

    // La fecha de registro de la reclasificación (fin del mes del servicio) se
    // comprueba según la configuración de gestión de propiedades: periodo
    // contable, fechas permitidas de la configuración de contabilidad y/o del
    // usuario, replicando cada control del estándar. Así el error aparece en la
    // validación y no al registrar el diario. Con todo desactivado solo se exige
    // que la línea tenga fecha de servicio.
    local procedure CheckPostingDate(ImportLine: Record "BeDyn Cleaning Import Line"): Text
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        PostingDate: Date;
        ErrText: Text;
        NoDateErr: Label 'La línea no tiene fecha de servicio.';
    begin
        if ImportLine."Service Date" = 0D then
            exit(NoDateErr);
        PostingDate := CalcDate('<CM>', ImportLine."Service Date");
        PropertySetup.GetInstance();

        if PropertySetup."Cleaning Check Acc. Period" then begin
            ErrText := CheckAccountingPeriod(PostingDate, ImportLine."Service Date");
            if ErrText <> '' then
                exit(ErrText);
        end;
        if PropertySetup."Cleaning Check User Setup Date" then begin
            ErrText := CheckUserSetupDate(PostingDate, ImportLine."Service Date");
            if ErrText <> '' then
                exit(ErrText);
        end;
        if PropertySetup."Cleaning Check GL Setup Date" then begin
            ErrText := CheckGLSetupDate(PostingDate, ImportLine."Service Date");
            if ErrText <> '' then
                exit(ErrText);
        end;
        exit('');
    end;

    // Periodo contable: debe existir un periodo que contenga la fecha y no estar
    // cerrado. Si la fecha cae después del último periodo definido, solo vale si
    // ese periodo empieza en el mismo mes (los periodos son mensuales).
    local procedure CheckAccountingPeriod(PostingDate: Date; ServiceDate: Date): Text
    var
        AccountingPeriod: Record "Accounting Period";
        NextPeriod: Record "Accounting Period";
        NoPeriodErr: Label 'La fecha de registro %1 (fin del mes del servicio %2) no tiene periodo contable definido.', Comment = '%1 = fecha registro, %2 = fecha servicio';
        ClosedErr: Label 'La fecha de registro %1 (fin del mes del servicio %2) cae en un periodo contable cerrado.', Comment = '%1 = fecha registro, %2 = fecha servicio';
    begin
        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
        if not AccountingPeriod.FindLast() then
            exit(StrSubstNo(NoPeriodErr, Format(PostingDate), Format(ServiceDate)));
        if AccountingPeriod.Closed then
            exit(StrSubstNo(ClosedErr, Format(PostingDate), Format(ServiceDate)));
        NextPeriod.SetFilter("Starting Date", '>%1', PostingDate);
        if NextPeriod.IsEmpty() and (CalcDate('<CM>', AccountingPeriod."Starting Date") <> PostingDate) then
            exit(StrSubstNo(NoPeriodErr, Format(PostingDate), Format(ServiceDate)));
        exit('');
    end;

    local procedure CheckGLSetupDate(PostingDate: Date; ServiceDate: Date): Text
    var
        GLSetup: Record "General Ledger Setup";
        GLSetupErr: Label 'La fecha de registro %1 (fin del mes del servicio %2) está fuera del rango "Permitir registro desde/hasta" (%3..%4) de la configuración de contabilidad.', Comment = '%1 = fecha registro, %2 = fecha servicio, %3, %4 = límites';
    begin
        GLSetup.Get();
        if ((GLSetup."Allow Posting From" <> 0D) and (PostingDate < GLSetup."Allow Posting From")) or
           ((GLSetup."Allow Posting To" <> 0D) and (PostingDate > GLSetup."Allow Posting To"))
        then
            exit(StrSubstNo(GLSetupErr, Format(PostingDate), Format(ServiceDate), Format(GLSetup."Allow Posting From"), Format(GLSetup."Allow Posting To")));
        exit('');
    end;

    // Solo aplica si el usuario actual tiene registro en configuración de
    // usuarios; sin registro no hay restricción por este control.
    local procedure CheckUserSetupDate(PostingDate: Date; ServiceDate: Date): Text
    var
        UserSetup: Record "User Setup";
        UserSetupErr: Label 'La fecha de registro %1 (fin del mes del servicio %2) está fuera del rango "Permitir registro desde/hasta" (%3..%4) del usuario %5 en la configuración de usuarios.', Comment = '%1 = fecha registro, %2 = fecha servicio, %3, %4 = límites, %5 = usuario';
    begin
        if not UserSetup.Get(UserId()) then
            exit('');
        if ((UserSetup."Allow Posting From" <> 0D) and (PostingDate < UserSetup."Allow Posting From")) or
           ((UserSetup."Allow Posting To" <> 0D) and (PostingDate > UserSetup."Allow Posting To"))
        then
            exit(StrSubstNo(UserSetupErr, Format(PostingDate), Format(ServiceDate), Format(UserSetup."Allow Posting From"), Format(UserSetup."Allow Posting To"), UserSetup."User ID"));
        exit('');
    end;

    // La factura a reclasificar es obligatoria (columna del fichero o asignación
    // en la hoja): debe ser una factura de compra registrada del proveedor de la
    // línea y no estar ya dimensionada por una reclasificación anterior.
    local procedure CheckAssignedInvoice(ImportLine: Record "BeDyn Cleaning Import Line"): Text
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        NoInvoiceErr: Label 'La línea no tiene factura de compra a reclasificar. Indícala en la columna factura del fichero o asígnala en la hoja.';
        InvoiceNotFoundErr: Label 'La factura registrada %1 no existe. Revisa la columna factura del fichero.', Comment = '%1 = nº factura';
        WrongVendorErr: Label 'La factura %1 no es del proveedor %2 de la línea.', Comment = '%1 = nº factura, %2 = proveedor';
        AlreadyDimensionedErr: Label 'La factura %1 ya se ha dimensionado.', Comment = '%1 = nº factura';
    begin
        if ImportLine."Invoice No." = '' then
            exit(NoInvoiceErr);
        if not PurchInvHeader.Get(ImportLine."Invoice No.") then
            exit(StrSubstNo(InvoiceNotFoundErr, ImportLine."Invoice No."));
        if PurchInvHeader."Buy-from Vendor No." <> ImportLine."Vendor No." then
            exit(StrSubstNo(WrongVendorErr, ImportLine."Invoice No.", ImportLine."Vendor No."));
        if PurchInvHeader."BeDyn Dimensioned" then
            exit(StrSubstNo(AlreadyDimensionedErr, ImportLine."Invoice No."));
        exit('');
    end;

    local procedure GetCatalogService(ImportLine: Record "BeDyn Cleaning Import Line"; var CleaningService: Record "BeDyn Cleaning Service"): Text
    var
        Vendor: Record Vendor;
        NoVendorErr: Label 'La línea no tiene proveedor.';
        VendorNotFoundErr: Label 'El proveedor %1 no existe. Revisa la columna proveedor del fichero.', Comment = '%1 = proveedor';
        NoServiceErr: Label 'El servicio %1 no existe en el catálogo del proveedor %2.', Comment = '%1 = servicio, %2 = proveedor';
    begin
        if ImportLine."Vendor No." = '' then
            exit(NoVendorErr);
        if not Vendor.Get(ImportLine."Vendor No.") then
            exit(StrSubstNo(VendorNotFoundErr, ImportLine."Vendor No."));
        if not CleaningService.Get(ImportLine."Vendor No.", ImportLine."Service Code") then
            exit(StrSubstNo(NoServiceErr, ImportLine."Service Code", ImportLine."Vendor No."));
        exit('');
    end;

    // El código de propiedad del CSV determina el proyecto: el de la ficha de
    // propiedad o, en su defecto, el proyecto con el mismo código (convención del
    // asistente de creación de propiedades).
    local procedure ResolveJob(var ImportLine: Record "BeDyn Cleaning Import Line"): Text
    var
        Property: Record "BeDyn Property";
        Job: Record Job;
        JobNo: Code[20];
        NoCodeErr: Label 'La fila no trae código de propiedad. Revisa la columna configurada en la configuración de gestión de propiedades.';
        NoPropertyErr: Label 'No existe la propiedad %1.', Comment = '%1 = código propiedad';
        NoJobErr: Label 'La propiedad %1 no tiene proyecto asociado ni existe un proyecto con su código.', Comment = '%1 = código propiedad';
        BlockedErr: Label 'El proyecto %1 está bloqueado o no está abierto.', Comment = '%1 = proyecto';
    begin
        ImportLine."Job No." := '';
        ImportLine."Job Task No." := '';

        if ImportLine."Property Code" = '' then
            exit(NoCodeErr);
        if not Property.Get(ImportLine."Property Code") then
            exit(StrSubstNo(NoPropertyErr, ImportLine."Property Code"));

        JobNo := Property."Job No.";
        if JobNo = '' then
            JobNo := Property."No.";
        if not Job.Get(JobNo) then
            exit(StrSubstNo(NoJobErr, ImportLine."Property Code"));
        if (Job.Blocked <> Job.Blocked::" ") or (Job.Status <> Job.Status::Open) then
            exit(StrSubstNo(BlockedErr, Job."No."));

        ImportLine."Job No." := Job."No.";
        exit('');
    end;

    local procedure ResolveAccountAndTask(var ImportLine: Record "BeDyn Cleaning Import Line"; CleaningService: Record "BeDyn Cleaning Service"): Text
    var
        NoAccountErr: Label 'El servicio %1 del proveedor %2 no tiene cuenta de gasto en el catálogo.', Comment = '%1 = servicio, %2 = proveedor';
        NoTaskErr: Label 'El servicio %1 del proveedor %2 no tiene tarea estándar en el catálogo.', Comment = '%1 = servicio, %2 = proveedor';
    begin
        ImportLine."G/L Account No." := CleaningService."Expense G/L Account No.";
        if ImportLine."G/L Account No." = '' then
            exit(StrSubstNo(NoAccountErr, CleaningService.Code, CleaningService."Vendor No."));

        if CleaningService."Job Task No." = '' then
            exit(StrSubstNo(NoTaskErr, CleaningService.Code, CleaningService."Vendor No."));

        exit(EnsureJobTask(ImportLine, CleaningService));
    end;

    // La tarea estándar debe existir en el proyecto de la propiedad; si falta
    // (propiedades anteriores a la plantilla actual) se crea automáticamente para
    // no atascar el proceso mensual.
    local procedure EnsureJobTask(var ImportLine: Record "BeDyn Cleaning Import Line"; CleaningService: Record "BeDyn Cleaning Service"): Text
    var
        JobTask: Record "Job Task";
        TaskTempl: Record "BeDyn Property Task Template";
        TaskDescription: Text[100];
        NotPostingErr: Label 'La tarea %1 del proyecto %2 no es de tipo Registro: no admite imputación de gastos.', Comment = '%1 = tarea, %2 = proyecto';
    begin
        if JobTask.Get(ImportLine."Job No.", CleaningService."Job Task No.") then begin
            if JobTask."Job Task Type" <> JobTask."Job Task Type"::Posting then
                exit(StrSubstNo(NotPostingErr, CleaningService."Job Task No.", ImportLine."Job No."));
            ImportLine."Job Task No." := CleaningService."Job Task No.";
            exit('');
        end;

        TaskDescription := CleaningService.Description;
        if TaskTempl.Get(CleaningService."Job Task No.") and (TaskTempl.Description <> '') then
            TaskDescription := TaskTempl.Description;
        if TaskDescription = '' then
            TaskDescription := CleaningService.Code;

        JobTask.Init();
        JobTask."Job No." := ImportLine."Job No.";
        JobTask."Job Task No." := CleaningService."Job Task No.";
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        JobTask.Validate(Description, TaskDescription);
        JobTask.Insert(true);

        ImportLine."Job Task No." := CleaningService."Job Task No.";
        exit('');
    end;

    // Los precios pactados avisan, no bloquean: si el importe no es cantidad ×
    // precio (con el margen de redondeo a céntimos del proveedor), la línea
    // queda validada igualmente con el motivo en la columna Aviso. El precio se
    // resuelve del más específico al más general: precio negociado de la
    // propiedad -> precio pactado del servicio en el catálogo. "Admitir
    // desviación precio" silencia el aviso.
    local procedure CheckAgreedPrice(var ImportLine: Record "BeDyn Cleaning Import Line"; CleaningService: Record "BeDyn Cleaning Service"): Text
    var
        ExpectedAmount: Decimal;
        PriceWarningLbl: Label 'El importe %1 no cuadra con %2 %3 × %4 = %5.', Comment = '%1 = importe, %2 = cantidad, %3 = unidad, %4 = precio, %5 = esperado';
    begin
        ImportLine."Warning Message" := '';
        ImportLine."Expected Unit Price" := GetAgreedPrice(ImportLine, CleaningService);
        if (ImportLine."Expected Unit Price" = 0) or ImportLine."Allow Deviation" then
            exit('');

        ExpectedAmount := Round(ImportLine.Quantity * ImportLine."Expected Unit Price", 0.01);
        if Abs(ImportLine.Amount - ExpectedAmount) <= LineRoundingTolerance then
            exit('');

        ImportLine."Warning Message" :=
            CopyStr(
                StrSubstNo(PriceWarningLbl, Format(ImportLine.Amount), Format(ImportLine.Quantity), CleaningService."Unit of Measure Code", Format(ImportLine."Expected Unit Price"), Format(ExpectedAmount)),
                1, MaxStrLen(ImportLine."Warning Message"));
        exit('');
    end;

    procedure GetAgreedPrice(ImportLine: Record "BeDyn Cleaning Import Line"; CleaningService: Record "BeDyn Cleaning Service"): Decimal
    var
        ServicePrice: Record "BeDyn Cleaning Service Price";
    begin
        if ServicePrice.Get(ImportLine."Vendor No.", ImportLine."Service Code", ImportLine."Property Code") then
            exit(ServicePrice.Price);
        exit(CleaningService."Default Price");
    end;
}
