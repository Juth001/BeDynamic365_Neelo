namespace BeDynamic.ReservationImport;

using BeDynamic.PropertyManagement;

codeunit 82802 "BeDyn Res. Import Process"
{
    // Crea los inquilinos, las reservas y las fianzas de las líneas validadas.
    //
    // Cada línea se procesa dentro de una función try: si una falla, se deshace
    // solo esa y queda marcada con su error, sin tirar abajo el resto del lote.
    // Las líneas en error y las de reservas ya cargadas que no toca actualizar se
    // dejan fuera, y el recuento final dice cuántas han sido.

    procedure ProcessBatch(BatchCode: Code[20])
    var
        ImportLine: Record "BeDyn Res. Import Line";
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        Created: Integer;
        Updated: Integer;
        Skipped: Integer;
        Failed: Integer;
        NothingToDoErr: Label 'No hay ninguna línea validada que procesar en este lote.';
        DoneMsg: Label 'Reservas creadas: %1. Actualizadas: %2. Omitidas: %3. Con error: %4.', Comment = '%1 = creadas, %2 = actualizadas, %3 = omitidas, %4 = con error';
    begin
        PropertySetup.GetInstance();

        ImportLine.SetRange("Batch Code", BatchCode);
        ImportLine.SetFilter(Status, '%1|%2', ImportLine.Status::Validated, ImportLine.Status::Warning);
        if ImportLine.IsEmpty() then
            Error(NothingToDoErr);

        if ImportLine.FindSet() then
            repeat
                ProcessOneLine(ImportLine, PropertySetup, Created, Updated, Skipped, Failed);
                ImportLine.Modify(true);
            until ImportLine.Next() = 0;

        Message(DoneMsg, Created, Updated, Skipped, Failed);
    end;

    local procedure ProcessOneLine(var ImportLine: Record "BeDyn Res. Import Line"; PropertySetup: Record "BeDyn Property Mgt. Setup"; var Created: Integer; var Updated: Integer; var Skipped: Integer; var Failed: Integer)
    var
        WasExisting: Boolean;
    begin
        // Ya cargada y la configuración dice no tocarla: se queda como está.
        if ImportLine."Existing Reservation" and (PropertySetup."Res. Import Duplicate Action" <> PropertySetup."Res. Import Duplicate Action"::Update) then begin
            Skipped += 1;
            exit;
        end;

        WasExisting := ImportLine."Existing Reservation";
        if not TryProcessLine(ImportLine, PropertySetup) then begin
            ImportLine.SetError(CopyStr(GetLastErrorText(), 1, MaxStrLen(ImportLine."Error Message")));
            Failed += 1;
            exit;
        end;

        ImportLine.Status := ImportLine.Status::Processed;
        if WasExisting then
            Updated += 1
        else
            Created += 1;
    end;

    [TryFunction]
    local procedure TryProcessLine(var ImportLine: Record "BeDyn Res. Import Line"; PropertySetup: Record "BeDyn Property Mgt. Setup")
    begin
        EnsureTypes(ImportLine, PropertySetup);
        EnsureTenant(ImportLine);
        WriteReservation(ImportLine);
        WriteDeposit(ImportLine, PropertySetup);
    end;

    // ------------------------------------------------------------ Maestros

    local procedure EnsureTypes(ImportLine: Record "BeDyn Res. Import Line"; PropertySetup: Record "BeDyn Property Mgt. Setup")
    var
        CustomerType: Record "BeDyn Customer Type";
        GuestType: Record "BeDyn Guest Type";
    begin
        if not PropertySetup."Res. Import Create Masters" then
            exit;
        if (ImportLine."Customer Type CSV" <> '') and not CustomerType.Get(ImportLine."Customer Type CSV") then begin
            CustomerType.Init();
            CustomerType.Code := ImportLine."Customer Type CSV";
            CustomerType.Description := ImportLine."Customer Type CSV";
            CustomerType.Insert(true);
        end;
        if (ImportLine."Guest Type CSV" <> '') and not GuestType.Get(ImportLine."Guest Type CSV") then begin
            GuestType.Init();
            GuestType.Code := ImportLine."Guest Type CSV";
            GuestType.Description := ImportLine."Guest Type CSV";
            GuestType.Insert(true);
        end;
    end;

    local procedure EnsureTenant(var ImportLine: Record "BeDyn Res. Import Line")
    var
        Tenant: Record "BeDyn Tenant";
    begin
        if ImportLine."Tenant No." <> '' then begin
            // El tipo de cliente solo se rellena si el inquilino no lo tenía: la
            // importación no pisa lo que ya hay en la ficha.
            if Tenant.Get(ImportLine."Tenant No.") then
                if (Tenant."Customer Type" = '') and (ImportLine."Customer Type CSV" <> '') then begin
                    Tenant."Customer Type" := ImportLine."Customer Type CSV";
                    Tenant.Modify(true);
                end;
            exit;
        end;

        Tenant.Init();
        Tenant."No." := '';
        Tenant.Insert(true);
        Tenant.Name := ImportLine."Guest Name";
        Tenant."Customer Type" := ImportLine."Customer Type CSV";
        Tenant.Modify(true);
        ImportLine."Tenant No." := Tenant."No.";
    end;

    // ------------------------------------------------------------ Reserva

    local procedure WriteReservation(var ImportLine: Record "BeDyn Res. Import Line")
    var
        Reservation: Record "BeDyn Reservation";
        IsNew: Boolean;
    begin
        IsNew := not Reservation.Get(ImportLine."Reservation No.");
        if IsNew then begin
            Reservation.Init();
            Reservation."No." := '';
            Reservation.Insert(true);
        end;

        Reservation.Validate("Property No.", ImportLine."Property No.");
        Reservation.Validate("Room No.", ImportLine."Room No.");
        Reservation.Validate("Tenant No.", ImportLine."Tenant No.");
        Reservation.Validate("Start Date", ImportLine."Check-In Date");
        Reservation.Validate("End Date", ImportLine."Check-Out Date");
        Reservation.Validate("Channel Code", ImportLine."Channel CSV");

        Reservation."Guest Type" := ImportLine."Guest Type CSV";
        Reservation."External Id" := ImportLine."External Id";
        Reservation."External Code" := ImportLine."External Code";
        Reservation."External Remark" := ImportLine.Remark;
        Reservation."Monthly Rent" := ImportLine."Monthly Rent";
        // Asignación directa: el importe manda el fichero, no la lista de precios.
        // Validar propiedad o fechas recalcula el importe, así que va después.
        Reservation."Price Basis" := Reservation."Price Basis"::"Per Month";
        Reservation."Rental Amount" := ImportLine."Contract Amount";

        ApplyStay(Reservation);
        Reservation.Modify(true);
        ImportLine."Reservation No." := Reservation."No.";
    end;

    // El fichero es histórico: el estado de la reserva sale de sus fechas contra
    // la fecha de trabajo, y con él las marcas de check-in y check-out.
    local procedure ApplyStay(var Reservation: Record "BeDyn Reservation")
    begin
        Reservation."Check-In Date/Time" := 0DT;
        Reservation."Check-Out Date/Time" := 0DT;

        if Reservation."End Date" <= WorkDate() then begin
            Reservation.Status := Reservation.Status::CheckedOut;
            Reservation."Check-In Date/Time" := CreateDateTime(Reservation."Start Date", Reservation."Check-In Time");
            Reservation."Check-Out Date/Time" := CreateDateTime(Reservation."End Date", Reservation."Check-Out Time");
            exit;
        end;
        if Reservation."Start Date" <= WorkDate() then begin
            Reservation.Status := Reservation.Status::CheckedIn;
            Reservation."Check-In Date/Time" := CreateDateTime(Reservation."Start Date", Reservation."Check-In Time");
            exit;
        end;
        Reservation.Status := Reservation.Status::Confirmed;
    end;

    // ------------------------------------------------------------ Fianza

    local procedure WriteDeposit(var ImportLine: Record "BeDyn Res. Import Line"; PropertySetup: Record "BeDyn Property Mgt. Setup")
    var
        Deposit: Record "BeDyn Deposit";
        DepositPosting: Codeunit "BeDyn Deposit Posting";
        IsNew: Boolean;
    begin
        if (ImportLine."Deposit Amount" = 0) and (ImportLine."Returned Amount" = 0) then
            exit;

        Deposit.SetRange("Reservation No.", ImportLine."Reservation No.");
        IsNew := not Deposit.FindFirst();
        if IsNew then begin
            Deposit.Init();
            Deposit."No." := '';
            Deposit."Reservation No." := ImportLine."Reservation No.";
            Deposit.Insert(true);
        end;

        // Todo por asignación directa: las validaciones de la ficha de fianza
        // están pensadas para el flujo manual (no dejan retocar una ya devuelta),
        // y aquí lo que se hace es reflejar el cuadre tal y como viene.
        Deposit."Reservation No." := ImportLine."Reservation No.";
        Deposit."Property No." := ImportLine."Property No.";
        Deposit."Room No." := ImportLine."Room No.";
        Deposit."Tenant No." := ImportLine."Tenant No.";
        Deposit.Amount := ImportLine."Deposit Amount";
        Deposit."Returned Amount" := ImportLine."Returned Amount";
        // El descuento negativo del origen es un artefacto de la hoja de cálculo;
        // ya se ha avisado en la validación y aquí no se propaga.
        if ImportLine."Retained Amount" > 0 then
            Deposit."Retained Amount" := ImportLine."Retained Amount"
        else
            Deposit."Retained Amount" := 0;
        Deposit.Status := DepositStatus(Deposit);
        if Deposit.Status in [Deposit.Status::Returned, Deposit.Status::Retained] then
            Deposit."Return Date" := ImportLine."Check-Out Date";
        Deposit.Modify(true);
        ImportLine."Deposit No." := Deposit."No.";

        // El asiento va dentro de la misma función try que el resto de la línea:
        // si el registro falla (periodo cerrado, cuenta bloqueada), se deshace la
        // línea entera y queda marcada con el motivo.
        if PropertySetup."Post Deposits on Import" then
            if (Deposit.Amount > 0) and not Deposit.IsPosted() then
                DepositPosting.PostDeposit(Deposit, 0D);
    end;

    local procedure DepositStatus(Deposit: Record "BeDyn Deposit"): Enum "BeDyn Deposit Status"
    begin
        // Mientras quede saldo por devolver, la fianza sigue en poder de la casa.
        if Deposit.Balance() > 0 then
            exit(Deposit.Status::Collected);
        if Deposit."Retained Amount" > 0 then
            exit(Deposit.Status::Retained);
        if Deposit."Returned Amount" > 0 then
            exit(Deposit.Status::Returned);
        exit(Deposit.Status::Pending);
    end;
}
