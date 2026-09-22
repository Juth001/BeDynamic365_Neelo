namespace BeDynamic.ReservationImport;

using BeDynamic.PropertyManagement;
using BeDynamic.PropertyWizard;
using Microsoft.Finance.Dimension;

codeunit 82801 "BeDyn Res. Import Validation"
{
    // Resuelve cada línea del fichero contra los maestros y la deja en Validada,
    // Con avisos o Error. Nada de esto crea registros: solo marca lo que la
    // importación haría, para poder revisarlo antes.
    //
    // La diferencia entre error y aviso es deliberada: error es lo que impide
    // crear la reserva (falta la propiedad, el canal no existe, se solapa con
    // otra); aviso es lo que se puede importar pero no cuadra con el fichero
    // (noches que no salen, balance de fianza que no cuadra).

    procedure ValidateBatch(BatchCode: Code[20])
    var
        ImportLine: Record "BeDyn Res. Import Line";
    begin
        ImportLine.SetRange("Batch Code", BatchCode);
        ImportLine.SetFilter(Status, '<>%1', ImportLine.Status::Processed);
        if ImportLine.FindSet() then
            repeat
                ValidateLine(ImportLine);
                ImportLine.Modify(true);
            until ImportLine.Next() = 0;
    end;

    procedure ValidateLine(var ImportLine: Record "BeDyn Res. Import Line")
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
    begin
        PropertySetup.GetInstance();
        ResetLine(ImportLine);

        CheckDates(ImportLine);
        CheckProperty(ImportLine);
        CheckRoom(ImportLine);
        CheckTenant(ImportLine, PropertySetup);
        CheckTypes(ImportLine, PropertySetup);
        CheckChannel(ImportLine, PropertySetup);
        CheckDeposit(ImportLine);
        CheckNights(ImportLine);
        CheckDuplicatesInBatch(ImportLine);
        CheckExistingReservation(ImportLine, PropertySetup);
        CheckOverlap(ImportLine);

        if ImportLine.Status = ImportLine.Status::Pending then
            ImportLine.Status := ImportLine.Status::Validated;
    end;

    local procedure ResetLine(var ImportLine: Record "BeDyn Res. Import Line")
    begin
        ImportLine.Status := ImportLine.Status::Pending;
        ImportLine."Error Message" := '';
        ImportLine."Warning Message" := '';
        ImportLine."Property No." := '';
        ImportLine."Room No." := '';
        ImportLine."Tenant No." := '';
        ImportLine."New Tenant" := false;
        ImportLine."Existing Reservation" := false;
        if ImportLine.Status <> ImportLine.Status::Processed then
            ImportLine."Reservation No." := '';
    end;

    // ------------------------------------------------------------ Fechas

    local procedure CheckDates(var ImportLine: Record "BeDyn Res. Import Line")
    var
        NoDatesErr: Label 'La fila no trae fecha de check-in o de check-out.';
        BadDatesErr: Label 'El check-out (%1) no es posterior al check-in (%2).', Comment = '%1 = fecha check-out, %2 = fecha check-in';
    begin
        if (ImportLine."Check-In Date" = 0D) or (ImportLine."Check-Out Date" = 0D) then begin
            ImportLine.SetError(NoDatesErr);
            exit;
        end;
        if ImportLine."Check-Out Date" <= ImportLine."Check-In Date" then
            ImportLine.SetError(StrSubstNo(BadDatesErr, ImportLine."Check-Out Date", ImportLine."Check-In Date"));
    end;

    // ------------------------------------------------------- Propiedad y unidad

    local procedure CheckProperty(var ImportLine: Record "BeDyn Res. Import Line")
    var
        Property: Record "BeDyn Property";
        NoPropertyErr: Label 'La fila no trae el Id interno de la propiedad.';
        UnknownPropertyErr: Label 'La propiedad %1 no existe.', Comment = '%1 = código de propiedad';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;
        if ImportLine."Property Code CSV" = '' then begin
            ImportLine.SetError(NoPropertyErr);
            exit;
        end;
        if not Property.Get(ImportLine."Property Code CSV") then begin
            ImportLine.SetError(StrSubstNo(UnknownPropertyErr, ImportLine."Property Code CSV"));
            exit;
        end;
        ImportLine."Property No." := Property."No.";
        CheckPropertyDimension(ImportLine);
    end;

    // La reserva hereda de la propiedad la dimensión PROPIEDAD; si la propiedad no
    // la tiene comunicada, la reserva nace sin ella y no se puede analizar.
    local procedure CheckPropertyDimension(var ImportLine: Record "BeDyn Res. Import Line")
    var
        DefaultDim: Record "Default Dimension";
        WizardSetup: Record "BeDyn Property Setup";
        MissingDimWarnLbl: Label 'La propiedad no tiene comunicada la dimensión %1: la reserva se creará sin ella.', Comment = '%1 = código de dimensión';
    begin
        if not WizardSetup.Get() then
            exit;
        if WizardSetup."Property Dimension Code" = '' then
            exit;
        if DefaultDim.Get(Database::"BeDyn Property", ImportLine."Property No.", WizardSetup."Property Dimension Code") then
            if DefaultDim."Dimension Value Code" <> '' then
                exit;
        ImportLine.AddWarning(StrSubstNo(MissingDimWarnLbl, WizardSetup."Property Dimension Code"));
    end;

    local procedure CheckRoom(var ImportLine: Record "BeDyn Res. Import Line")
    var
        RoomNo: Code[20];
        UnitCode: Text;
        UnknownRoomErr: Label 'No se ha podido identificar la subpropiedad %1 dentro de la propiedad %2.', Comment = '%1 = id de unidad, %2 = código de propiedad';
        PrefixWarnLbl: Label 'El Id de unidad %1 no empieza por el código de la propiedad %2.', Comment = '%1 = id de unidad, %2 = código de propiedad';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;

        UnitCode := ImportLine."Unit Code CSV";
        if (UnitCode <> '') and (ImportLine."Property No." <> '') then
            if not UnitCode.StartsWith(ImportLine."Property No.") then
                ImportLine.AddWarning(StrSubstNo(PrefixWarnLbl, ImportLine."Unit Code CSV", ImportLine."Property No."));

        if not ResolveRoom(ImportLine."Property No.", ImportLine."Unit Code CSV", RoomNo) then begin
            ImportLine.SetError(StrSubstNo(UnknownRoomErr, ImportLine."Unit Code CSV", ImportLine."Property No."));
            exit;
        end;
        ImportLine."Room No." := RoomNo;
    end;

    // Casa el Id de unidad del fichero con una subpropiedad. Primero por el Id
    // externo de la subpropiedad, que es donde debería estar; si no, por el patrón
    // del código: el último segmento es el número de habitación (006 -> H6) y el
    // 000 significa la propiedad entera, que en el modelo es una reserva sin
    // subpropiedad. Devuelve false solo si no ha sabido resolverlo.
    procedure ResolveRoom(PropertyNo: Code[20]; UnitCode: Code[50]; var RoomNo: Code[20]): Boolean
    var
        PropertyRoom: Record "BeDyn Property Room";
        Segments: List of [Text];
        RoomNumber: Integer;
        Suffix: Text;
        UnitCodeText: Text;
    begin
        RoomNo := '';
        if UnitCode = '' then
            exit(true);

        PropertyRoom.SetRange("Property No.", PropertyNo);
        PropertyRoom.SetRange("External Id", UnitCode);
        if PropertyRoom.FindFirst() then begin
            RoomNo := PropertyRoom."Room No.";
            exit(true);
        end;

        UnitCodeText := UnitCode;
        Segments := UnitCodeText.Split('-');
        if Segments.Count() < 2 then
            exit(false);
        Suffix := Segments.Get(Segments.Count());
        if not Evaluate(RoomNumber, Suffix) then
            exit(false);
        // 000: la reserva es de la propiedad completa, sin subpropiedad.
        if RoomNumber = 0 then
            exit(true);

        RoomNo := CopyStr('H' + Format(RoomNumber), 1, MaxStrLen(RoomNo));
        exit(PropertyRoom.Get(PropertyNo, RoomNo));
    end;

    // ------------------------------------------------------------ Inquilino

    local procedure CheckTenant(var ImportLine: Record "BeDyn Res. Import Line"; PropertySetup: Record "BeDyn Property Mgt. Setup")
    var
        TenantNo: Code[20];
        NoNameErr: Label 'La fila no trae el nombre del huésped.';
        NoTenantErr: Label 'No hay ningún inquilino que se llame %1, y la configuración no permite darlo de alta en la importación.', Comment = '%1 = nombre del huésped';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;
        if ImportLine."Guest Name" = '' then begin
            ImportLine.SetError(NoNameErr);
            exit;
        end;

        TenantNo := FindTenantByName(ImportLine."Guest Name");
        if TenantNo <> '' then begin
            ImportLine."Tenant No." := TenantNo;
            exit;
        end;

        if not PropertySetup."Res. Import Create Masters" then begin
            ImportLine.SetError(StrSubstNo(NoTenantErr, ImportLine."Guest Name"));
            exit;
        end;
        ImportLine."New Tenant" := true;
    end;

    // Busca por nombre normalizado, que es lo único que trae el fichero. Los
    // acentos y los espacios de más se ignoran a propósito: en el origen conviven
    // "Sergio Ramón" y "Sergio Ramon" para la misma persona.
    procedure FindTenantByName(GuestName: Text): Code[20]
    var
        Tenant: Record "BeDyn Tenant";
        Normalized: Text;
    begin
        Normalized := NormalizeName(GuestName);
        if Normalized = '' then
            exit('');
        if Tenant.FindSet() then
            repeat
                if NormalizeName(Tenant.Name) = Normalized then
                    exit(Tenant."No.");
            until Tenant.Next() = 0;
        exit('');
    end;

    procedure NormalizeName(GuestName: Text) Result: Text
    var
        DoubleSpaceTok: Label '  ', Locked = true;
        SpaceTok: Label ' ', Locked = true;
        AccentedTok: Label 'ÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ', Locked = true;
        PlainTok: Label 'AAAAAEEEEIIIIOOOOOUUUUNC', Locked = true;
    begin
        Result := ConvertStr(UpperCase(GuestName), AccentedTok, PlainTok);
        while Result.Contains(DoubleSpaceTok) do
            Result := Result.Replace(DoubleSpaceTok, SpaceTok);
        exit(DelChr(Result, '<>', ' '));
    end;

    // ------------------------------------------------------- Tipos y canal

    local procedure CheckTypes(var ImportLine: Record "BeDyn Res. Import Line"; PropertySetup: Record "BeDyn Property Mgt. Setup")
    var
        CustomerType: Record "BeDyn Customer Type";
        GuestType: Record "BeDyn Guest Type";
        UnknownCustomerTypeErr: Label 'El tipo de cliente %1 no existe, y la configuración no permite darlo de alta en la importación.', Comment = '%1 = tipo de cliente';
        UnknownGuestTypeErr: Label 'El tipo de huésped %1 no existe, y la configuración no permite darlo de alta en la importación.', Comment = '%1 = tipo de huésped';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;
        if PropertySetup."Res. Import Create Masters" then
            exit;

        if (ImportLine."Customer Type CSV" <> '') and not CustomerType.Get(ImportLine."Customer Type CSV") then begin
            ImportLine.SetError(StrSubstNo(UnknownCustomerTypeErr, ImportLine."Customer Type CSV"));
            exit;
        end;
        if (ImportLine."Guest Type CSV" <> '') and not GuestType.Get(ImportLine."Guest Type CSV") then
            ImportLine.SetError(StrSubstNo(UnknownGuestTypeErr, ImportLine."Guest Type CSV"));
    end;

    // Los canales nunca se crean solos: son valores de dimensión y afectan al
    // análisis contable, así que se dan de alta a mano.
    local procedure CheckChannel(var ImportLine: Record "BeDyn Res. Import Line"; PropertySetup: Record "BeDyn Property Mgt. Setup")
    var
        DimValue: Record "Dimension Value";
        NoChannelWarnLbl: Label 'La reserva no trae canal.';
        NoDimensionErr: Label 'Hay reservas con canal (%1) pero no hay dimensión de canal configurada en la configuración de gestión de propiedades.', Comment = '%1 = canal';
        UnknownChannelErr: Label 'El canal %1 no existe como valor de la dimensión %2. Créalo en los valores de dimensión y vuelve a validar.', Comment = '%1 = canal, %2 = código de dimensión';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;
        if ImportLine."Channel CSV" = '' then begin
            ImportLine.AddWarning(NoChannelWarnLbl);
            exit;
        end;
        if PropertySetup."Channel Dimension Code" = '' then begin
            ImportLine.SetError(StrSubstNo(NoDimensionErr, ImportLine."Channel CSV"));
            exit;
        end;
        if not DimValue.Get(PropertySetup."Channel Dimension Code", ImportLine."Channel CSV") then
            ImportLine.SetError(StrSubstNo(UnknownChannelErr, ImportLine."Channel CSV", PropertySetup."Channel Dimension Code"));
    end;

    // ------------------------------------------------------- Fianza y noches

    // El balance del fichero sale de fianza menos devuelto menos descontado. Se
    // recalcula porque en el origen hay filas que no cuadran (devoluciones sobre
    // fianzas de importe cero, descuentos negativos).
    local procedure CheckDeposit(var ImportLine: Record "BeDyn Res. Import Line")
    var
        CalculatedBalance: Decimal;
        BalanceWarnLbl: Label 'El balance del fichero (%1) no cuadra con fianza menos devuelto menos descontado (%2).', Comment = '%1 = balance del fichero, %2 = balance calculado';
        NegativeRetainedWarnLbl: Label 'La cantidad descontada es negativa (%1).', Comment = '%1 = importe descontado';
        ReturnedTooHighWarnLbl: Label 'La cantidad devuelta (%1) supera la fianza (%2).', Comment = '%1 = importe devuelto, %2 = importe de la fianza';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;

        CalculatedBalance := ImportLine."Deposit Amount" - ImportLine."Returned Amount" - ImportLine."Retained Amount";
        if CalculatedBalance <> ImportLine."Balance Amount" then
            ImportLine.AddWarning(StrSubstNo(BalanceWarnLbl, ImportLine."Balance Amount", CalculatedBalance));
        if ImportLine."Retained Amount" < 0 then
            ImportLine.AddWarning(StrSubstNo(NegativeRetainedWarnLbl, ImportLine."Retained Amount"));
        if ImportLine."Returned Amount" > ImportLine."Deposit Amount" then
            ImportLine.AddWarning(StrSubstNo(ReturnedTooHighWarnLbl, ImportLine."Returned Amount", ImportLine."Deposit Amount"));
    end;

    local procedure CheckNights(var ImportLine: Record "BeDyn Res. Import Line")
    var
        CalculatedNights: Integer;
        NightsWarnLbl: Label 'Las noches del fichero (%1) no coinciden con las que van del check-in al check-out (%2).', Comment = '%1 = noches del fichero, %2 = noches calculadas';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;
        if ImportLine."Nights CSV" = 0 then
            exit;
        CalculatedNights := ImportLine."Check-Out Date" - ImportLine."Check-In Date";
        if CalculatedNights <> ImportLine."Nights CSV" then
            ImportLine.AddWarning(StrSubstNo(NightsWarnLbl, ImportLine."Nights CSV", CalculatedNights));
    end;

    // ------------------------------------------------------------ Duplicados

    local procedure CheckDuplicatesInBatch(var ImportLine: Record "BeDyn Res. Import Line")
    var
        OtherLine: Record "BeDyn Res. Import Line";
        DuplicateIdErr: Label 'El Id de reserva %1 aparece más de una vez en el fichero (filas %2 y %3).', Comment = '%1 = id de reserva, %2 = fila, %3 = fila';
        DuplicateCodeErr: Label 'El código de reserva %1 aparece más de una vez en el fichero (filas %2 y %3).', Comment = '%1 = código de reserva, %2 = fila, %3 = fila';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;

        OtherLine.SetRange("Batch Code", ImportLine."Batch Code");
        OtherLine.SetRange("External Id", ImportLine."External Id");
        OtherLine.SetFilter("Entry No.", '<>%1', ImportLine."Entry No.");
        if OtherLine.FindFirst() then begin
            ImportLine.SetError(StrSubstNo(DuplicateIdErr, ImportLine."External Id", ImportLine."Row No.", OtherLine."Row No."));
            exit;
        end;

        if ImportLine."External Code" = '' then
            exit;
        OtherLine.Reset();
        OtherLine.SetRange("Batch Code", ImportLine."Batch Code");
        OtherLine.SetRange("External Code", ImportLine."External Code");
        OtherLine.SetFilter("Entry No.", '<>%1', ImportLine."Entry No.");
        if OtherLine.FindFirst() then
            ImportLine.SetError(StrSubstNo(DuplicateCodeErr, ImportLine."External Code", ImportLine."Row No.", OtherLine."Row No."));
    end;

    local procedure CheckExistingReservation(var ImportLine: Record "BeDyn Res. Import Line"; PropertySetup: Record "BeDyn Property Mgt. Setup")
    var
        Reservation: Record "BeDyn Reservation";
        Differences: Text;
        AlreadyLoadedErr: Label 'La reserva %1 ya está cargada como %2.', Comment = '%1 = id externo, %2 = nº de reserva';
        NoChangesWarnLbl: Label 'Ya cargada como %1, sin diferencias con el fichero.', Comment = '%1 = nº de reserva';
        ChangesWarnLbl: Label 'Ya cargada como %1 y no se va a modificar. Difiere en: %2.', Comment = '%1 = nº de reserva, %2 = lista de diferencias';
        CodeTakenErr: Label 'El código de reserva %1 ya lo tiene la reserva %2, que corresponde a otro Id externo.', Comment = '%1 = código de reserva, %2 = nº de reserva';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;

        // El código externo no se puede repetir entre reservas distintas.
        if ImportLine."External Code" <> '' then begin
            Reservation.SetRange("External Code", ImportLine."External Code");
            Reservation.SetFilter("External Id", '<>%1', ImportLine."External Id");
            if Reservation.FindFirst() then begin
                ImportLine.SetError(StrSubstNo(CodeTakenErr, ImportLine."External Code", Reservation."No."));
                exit;
            end;
        end;

        Reservation.Reset();
        Reservation.SetRange("External Id", ImportLine."External Id");
        if not Reservation.FindFirst() then
            exit;

        ImportLine."Existing Reservation" := true;
        ImportLine."Reservation No." := Reservation."No.";

        case PropertySetup."Res. Import Duplicate Action" of
            PropertySetup."Res. Import Duplicate Action"::Fail:
                ImportLine.SetError(StrSubstNo(AlreadyLoadedErr, ImportLine."External Id", Reservation."No."));
            PropertySetup."Res. Import Duplicate Action"::Warn:
                begin
                    Differences := DescribeDifferences(ImportLine, Reservation);
                    if Differences = '' then
                        ImportLine.AddWarning(StrSubstNo(NoChangesWarnLbl, Reservation."No."))
                    else
                        ImportLine.AddWarning(StrSubstNo(ChangesWarnLbl, Reservation."No.", Differences));
                end;
        end;
    end;

    // Enumera en qué difiere el fichero de la reserva ya cargada, para poder
    // decidir sin abrir las dos fichas.
    local procedure DescribeDifferences(ImportLine: Record "BeDyn Res. Import Line"; Reservation: Record "BeDyn Reservation") Differences: Text
    begin
        AddDifference(Differences, Reservation.FieldCaption("Start Date"), Format(Reservation."Start Date"), Format(ImportLine."Check-In Date"));
        AddDifference(Differences, Reservation.FieldCaption("End Date"), Format(Reservation."End Date"), Format(ImportLine."Check-Out Date"));
        AddDifference(Differences, Reservation.FieldCaption("Room No."), Reservation."Room No.", ImportLine."Room No.");
        AddDifference(Differences, Reservation.FieldCaption("Tenant No."), Reservation."Tenant No.", ImportLine."Tenant No.");
        AddDifference(Differences, Reservation.FieldCaption("Rental Amount"), Format(Reservation."Rental Amount"), Format(ImportLine."Contract Amount"));
        AddDifference(Differences, Reservation.FieldCaption("Monthly Rent"), Format(Reservation."Monthly Rent"), Format(ImportLine."Monthly Rent"));
        AddDifference(Differences, Reservation.FieldCaption("Channel Code"), Reservation."Channel Code", ImportLine."Channel CSV");
    end;

    local procedure AddDifference(var Differences: Text; FieldName: Text; CurrentValue: Text; FileValue: Text)
    var
        SeparatorTok: Label ', ', Locked = true;
        DifferenceLbl: Label '%1 (%2 -> %3)', Comment = '%1 = campo, %2 = valor actual, %3 = valor del fichero';
    begin
        if CurrentValue = FileValue then
            exit;
        if Differences <> '' then
            Differences += SeparatorTok;
        Differences += StrSubstNo(DifferenceLbl, FieldName, CurrentValue, FileValue);
    end;

    // ------------------------------------------------------------ Solapes

    // Una subpropiedad no puede tener dos estancias a la vez, y una reserva de la
    // propiedad completa (sin subpropiedad) choca con cualquier subpropiedad.
    local procedure CheckOverlap(var ImportLine: Record "BeDyn Res. Import Line")
    var
        Reservation: Record "BeDyn Reservation";
        OtherLine: Record "BeDyn Res. Import Line";
        OverlapReservationErr: Label 'Se solapa con la reserva %1 de %2 a %3.', Comment = '%1 = nº de reserva, %2 = fecha inicio, %3 = fecha fin';
        OverlapLineErr: Label 'Se solapa con la fila %1 del propio fichero (%2 a %3).', Comment = '%1 = fila, %2 = fecha inicio, %3 = fecha fin';
    begin
        if ImportLine.Status = ImportLine.Status::Error then
            exit;

        Reservation.SetRange("Property No.", ImportLine."Property No.");
        Reservation.SetFilter(Status, '<>%1', Reservation.Status::Cancelled);
        if ImportLine."Reservation No." <> '' then
            Reservation.SetFilter("No.", '<>%1', ImportLine."Reservation No.");
        if Reservation.FindSet() then
            repeat
                if RoomsCollide(ImportLine."Room No.", Reservation."Room No.") then
                    if DatesOverlap(ImportLine."Check-In Date", ImportLine."Check-Out Date", Reservation."Start Date", Reservation."End Date") then begin
                        ImportLine.SetError(StrSubstNo(OverlapReservationErr, Reservation."No.", Reservation."Start Date", Reservation."End Date"));
                        exit;
                    end;
            until Reservation.Next() = 0;

        OtherLine.SetRange("Batch Code", ImportLine."Batch Code");
        OtherLine.SetRange("Property No.", ImportLine."Property No.");
        OtherLine.SetFilter("Entry No.", '<>%1', ImportLine."Entry No.");
        if OtherLine.FindSet() then
            repeat
                if RoomsCollide(ImportLine."Room No.", OtherLine."Room No.") then
                    if DatesOverlap(ImportLine."Check-In Date", ImportLine."Check-Out Date", OtherLine."Check-In Date", OtherLine."Check-Out Date") then begin
                        ImportLine.SetError(StrSubstNo(OverlapLineErr, OtherLine."Row No.", OtherLine."Check-In Date", OtherLine."Check-Out Date"));
                        exit;
                    end;
            until OtherLine.Next() = 0;
    end;

    local procedure RoomsCollide(RoomNo: Code[20]; OtherRoomNo: Code[20]): Boolean
    begin
        // Sin subpropiedad se ocupa la propiedad entera: choca con todas.
        if (RoomNo = '') or (OtherRoomNo = '') then
            exit(true);
        exit(RoomNo = OtherRoomNo);
    end;

    // Intervalos semiabiertos: el día del check-out queda libre para la siguiente
    // estancia, que es como encadena el propio fichero las reservas seguidas.
    local procedure DatesOverlap(FromDate: Date; ToDate: Date; OtherFrom: Date; OtherTo: Date): Boolean
    begin
        if (FromDate = 0D) or (ToDate = 0D) or (OtherFrom = 0D) or (OtherTo = 0D) then
            exit(false);
        exit((FromDate < OtherTo) and (OtherFrom < ToDate));
    end;
}
