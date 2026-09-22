namespace BeDynamic.PropertyManagement;

using Microsoft.Finance.Dimension;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;

codeunit 82505 "BeDyn Property Billing Mgt."
{
    var
        NoDepositPriceErr: Label 'No se puede calcular la fianza de la reserva %1 porque no hay precio mensual definido para la propiedad %2.', Comment = '%1 = Nº reserva, %2 = Nº propiedad';
        NoServiceAccountErr: Label 'No hay cuenta de servicios en la configuración de gestión de propiedades para facturar el servicio %1.', Comment = '%1 = Código servicio';
        NoCustomerErr: Label 'El inquilino %1 no tiene cliente asociado. Asigne un Nº cliente en la ficha del inquilino para poder facturar.', Comment = '%1 = Nº inquilino';
        RentRoomLineTxt: Label 'Alquiler %1 hab. %2: %3 - %4', Comment = '%1 = Nº propiedad, %2 = Nº subpropiedad, %3 = Fecha desde, %4 = Fecha hasta';
        RentLineTxt: Label 'Alquiler %1: %2 - %3', Comment = '%1 = Nº propiedad, %2 = Fecha desde, %3 = Fecha hasta';
        DepositLineTxt: Label 'Fianza %1 mes(es) - no sujeta a IVA', Comment = '%1 = Meses de fianza';

    // Llamado al confirmar la reserva. Para reservas mensuales crea la fianza (según los
    // meses definidos en la propiedad) y la factura de la primera mensualidad, que incluye
    // los servicios y, si así está configurado, la línea de fianza sin IVA.
    procedure OnReservationConfirmed(var Reservation: Record "BeDyn Reservation")
    begin
        if Reservation."Price Basis" <> Reservation."Price Basis"::"Per Month" then
            exit;
        CreateDepositIfNeeded(Reservation);
        CreateMonthlyInvoice(Reservation, Reservation."Start Date", WorkDate(), true);
    end;

    // Reservas por noche: se facturan íntegras al check-in o al check-out según el
    // momento de facturación de la reserva.
    procedure OnCheckIn(var Reservation: Record "BeDyn Reservation")
    begin
        if Reservation."Billing Moment" = Reservation."Billing Moment"::"At Check-In" then
            CreateNightlyInvoice(Reservation);
    end;

    procedure OnCheckOut(var Reservation: Record "BeDyn Reservation")
    begin
        if Reservation."Billing Moment" = Reservation."Billing Moment"::"At Check-Out" then
            CreateNightlyInvoice(Reservation);
    end;

    procedure CanInvoiceReservation(Reservation: Record "BeDyn Reservation"): Boolean
    var
        Tenant: Record "BeDyn Tenant";
    begin
        if Reservation."Tenant No." = '' then
            exit(false);
        if not Tenant.Get(Reservation."Tenant No.") then
            exit(false);
        exit(Tenant."Customer No." <> '');
    end;

    // Factura las mensualidades pendientes de la reserva hasta el fin del mes de
    // BillUpToDate: una línea por mes natural, con prorrateo a /30 en los meses parciales.
    // Devuelve false si no hay nada que facturar.
    procedure CreateMonthlyInvoice(var Reservation: Record "BeDyn Reservation"; BillUpToDate: Date; PostingDate: Date; FirstInvoice: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
        PropertyPriceMgt: Codeunit "BeDyn Property Price Mgt.";
        LineNo: Integer;
        FromDate: Date;
        TargetUntil: Date;
        ChunkStart: Date;
        ChunkEnd: Date;
        Amount: Decimal;
    begin
        Reservation.TestField("Start Date");
        Reservation.TestField("End Date");
        TargetUntil := CalcDate('<CM>', BillUpToDate);
        if TargetUntil > Reservation."End Date" - 1 then
            TargetUntil := Reservation."End Date" - 1;
        FromDate := GetNextUnbilledDate(Reservation);
        if FromDate > TargetUntil then
            exit(false);

        CreateInvoiceHeader(Reservation, PostingDate, SalesHeader);

        ChunkStart := FromDate;
        while ChunkStart <= TargetUntil do begin
            ChunkEnd := CalcDate('<CM>', ChunkStart);
            if ChunkEnd > TargetUntil then
                ChunkEnd := TargetUntil;
            Amount := PropertyPriceMgt.CalcCalendarPeriodAmount(Reservation."Property No.", Reservation."Room No.", ChunkStart, ChunkEnd);
            AddRentLine(SalesHeader, Reservation, ChunkStart, ChunkEnd, Amount, LineNo);
            ChunkStart := ChunkEnd + 1;
        end;

        if FirstInvoice then begin
            AddServiceLines(SalesHeader, Reservation, LineNo);
            AddDepositLineIfConfigured(SalesHeader, Reservation, LineNo);
        end;

        SalesHeader."Reservation Billed Until" := TargetUntil;
        SalesHeader.Modify();

        PostIfConfigured(SalesHeader);
        exit(true);
    end;

    // Factura la estancia completa de una reserva por noche, con sus servicios.
    procedure CreateNightlyInvoice(var Reservation: Record "BeDyn Reservation"): Boolean
    var
        SalesHeader: Record "Sales Header";
        LineNo: Integer;
        LastNight: Date;
    begin
        Reservation.TestField("Start Date");
        Reservation.TestField("End Date");
        LastNight := Reservation."End Date" - 1;
        if GetNextUnbilledDate(Reservation) > LastNight then
            exit(false);

        CreateInvoiceHeader(Reservation, WorkDate(), SalesHeader);
        AddRentLine(SalesHeader, Reservation, Reservation."Start Date", LastNight, Reservation."Rental Amount", LineNo);
        AddServiceLines(SalesHeader, Reservation, LineNo);

        SalesHeader."Reservation Billed Until" := LastNight;
        SalesHeader.Modify();

        PostIfConfigured(SalesHeader);
        exit(true);
    end;

    local procedure CreateDepositIfNeeded(Reservation: Record "BeDyn Reservation")
    var
        Property: Record "BeDyn Property";
        Deposit: Record "BeDyn Deposit";
        PropertyPriceMgt: Codeunit "BeDyn Property Price Mgt.";
        MonthlyPrice: Decimal;
    begin
        Property.Get(Reservation."Property No.");
        if Property."Deposit Months" = 0 then
            exit;
        Deposit.SetRange("Reservation No.", Reservation."No.");
        if not Deposit.IsEmpty() then
            exit;
        if not PropertyPriceMgt.GetPrice(Reservation."Property No.", Reservation."Room No.", Reservation."Price Basis"::"Per Month", Reservation."Start Date", MonthlyPrice) then
            Error(NoDepositPriceErr, Reservation."No.", Reservation."Property No.");
        if MonthlyPrice = 0 then
            Error(NoDepositPriceErr, Reservation."No.", Reservation."Property No.");

        Deposit.Init();
        Deposit."No." := '';
        Deposit.Insert(true);
        Deposit.Validate("Reservation No.", Reservation."No.");
        Deposit.Months := Property."Deposit Months";
        Deposit.Amount := Round(Property."Deposit Months" * MonthlyPrice, 0.01);
        Deposit.Modify(true);
    end;

    local procedure CreateInvoiceHeader(Reservation: Record "BeDyn Reservation"; PostingDate: Date; var SalesHeader: Record "Sales Header")
    var
        Tenant: Record "BeDyn Tenant";
    begin
        Reservation.TestField("Tenant No.");
        Tenant.Get(Reservation."Tenant No.");
        if Tenant."Customer No." = '' then
            Error(NoCustomerErr, Tenant."No.");

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Tenant."Customer No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", PostingDate);
        SalesHeader."Reservation No." := Reservation."No.";
        SalesHeader.Modify(true);
    end;

    local procedure AddRentLine(SalesHeader: Record "Sales Header"; Reservation: Record "BeDyn Reservation"; FromDate: Date; ToDate: Date; Amount: Decimal; var LineNo: Integer)
    var
        Property: Record "BeDyn Property";
        PropertyRoom: Record "BeDyn Property Room";
        SalesLine: Record "Sales Line";
        VariantCode: Code[10];
        Description: Text;
    begin
        Property.Get(Reservation."Property No.");
        Property.TestField("Item No.");
        VariantCode := '';
        if Reservation."Room No." <> '' then
            if PropertyRoom.Get(Reservation."Property No.", Reservation."Room No.") then
                VariantCode := PropertyRoom."Variant Code";

        if Reservation."Room No." <> '' then
            Description := StrSubstNo(RentRoomLineTxt, Reservation."Property No.", Reservation."Room No.", FromDate, ToDate)
        else
            Description := StrSubstNo(RentLineTxt, Reservation."Property No.", FromDate, ToDate);

        InitLine(SalesHeader, SalesLine, LineNo);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Property."Item No.");
        if VariantCode <> '' then
            SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Validate(Description, CopyStr(Description, 1, MaxStrLen(SalesLine.Description)));
        SalesLine.Modify(true);
    end;

    local procedure AddServiceLines(SalesHeader: Record "Sales Header"; Reservation: Record "BeDyn Reservation"; var LineNo: Integer)
    var
        ReservationService: Record "BeDyn Reservation Service";
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        SalesLine: Record "Sales Line";
        PropertyDimMgt: Codeunit "BeDyn Property Dimension Mgt.";
        DimMgt: Codeunit DimensionManagement;
        GLAccountNo: Code[20];
    begin
        PropertySetup.GetInstance();
        ReservationService.SetRange("Reservation No.", Reservation."No.");
        if ReservationService.FindSet() then
            repeat
                GLAccountNo := PropertySetup."Service G/L Account No.";
                if GLAccountNo = '' then
                    Error(NoServiceAccountErr, ReservationService."Service Code");

                InitLine(SalesHeader, SalesLine, LineNo);
                SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
                SalesLine.Validate("No.", GLAccountNo);
                SalesLine.Validate(Quantity, ReservationService.Quantity);
                SalesLine.Validate("Unit Price", ReservationService."Unit Price");
                if ReservationService.Description <> '' then
                    SalesLine.Validate(Description, ReservationService.Description);
                SalesLine."Dimension Set ID" :=
                    PropertyDimMgt.AddServiceDefaultDims(SalesLine."Dimension Set ID", ReservationService."Service Code");
                DimMgt.UpdateGlobalDimFromDimSetID(
                    SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
                SalesLine.Modify(true);
            until ReservationService.Next() = 0;
    end;

    local procedure AddDepositLineIfConfigured(var SalesHeader: Record "Sales Header"; Reservation: Record "BeDyn Reservation"; var LineNo: Integer)
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        Deposit: Record "BeDyn Deposit";
        SalesLine: Record "Sales Line";
    begin
        PropertySetup.GetInstance();
        if PropertySetup."Deposit Billing Method" <> PropertySetup."Deposit Billing Method"::"First Invoice" then
            exit;
        Deposit.SetRange("Reservation No.", Reservation."No.");
        Deposit.SetRange(Status, Deposit.Status::Pending);
        if not Deposit.FindFirst() then
            exit;
        PropertySetup.TestField("Deposit G/L Account No.");

        InitLine(SalesHeader, SalesLine, LineNo);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", PropertySetup."Deposit G/L Account No.");
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", Deposit.Amount);
        SalesLine.Validate(Description, StrSubstNo(DepositLineTxt, Deposit.Months));
        SalesLine.Modify(true);

        SalesHeader."Deposit No." := Deposit."No.";
    end;

    local procedure InitLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var LineNo: Integer)
    begin
        LineNo += 10000;
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);
    end;

    // Primer día aún no facturado, considerando lo registrado (Facturado hasta) y los
    // borradores de factura existentes, para no facturar dos veces el mismo periodo.
    local procedure GetNextUnbilledDate(Reservation: Record "BeDyn Reservation"): Date
    var
        SalesHeader: Record "Sales Header";
        LastBilled: Date;
    begin
        LastBilled := Reservation."Invoiced Until";
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Reservation No.", Reservation."No.");
        if SalesHeader.FindSet() then
            repeat
                if SalesHeader."Reservation Billed Until" > LastBilled then
                    LastBilled := SalesHeader."Reservation Billed Until";
            until SalesHeader.Next() = 0;
        if LastBilled = 0D then
            exit(Reservation."Start Date");
        exit(LastBilled + 1);
    end;

    local procedure PostIfConfigured(var SalesHeader: Record "Sales Header")
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        SalesPost: Codeunit "Sales-Post";
    begin
        PropertySetup.GetInstance();
        if not PropertySetup."Auto-Post Rental Invoices" then
            exit;
        SalesPost.Run(SalesHeader);
    end;

    // Al registrar una factura vinculada a una reserva se actualiza su "Facturado hasta"
    // y, si incluía la fianza, esta pasa a Cobrada con el nº de la factura registrada.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure HandleOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20])
    var
        Reservation: Record "BeDyn Reservation";
        Deposit: Record "BeDyn Deposit";
    begin
        if SalesHeader."Reservation No." = '' then
            exit;
        if SalesInvHdrNo = '' then
            exit;

        if Reservation.Get(SalesHeader."Reservation No.") then
            if SalesHeader."Reservation Billed Until" > Reservation."Invoiced Until" then begin
                Reservation."Invoiced Until" := SalesHeader."Reservation Billed Until";
                Reservation.Modify();
            end;

        if SalesHeader."Deposit No." <> '' then
            if Deposit.Get(SalesHeader."Deposit No.") then
                if Deposit.Status = Deposit.Status::Pending then begin
                    Deposit.Status := Deposit.Status::Collected;
                    Deposit."Collection Date" := SalesHeader."Posting Date";
                    Deposit."Document No." := SalesInvHdrNo;
                    Deposit.Modify();
                end;
    end;
}
