namespace BeDynamic.PropertyManagement;

using Microsoft.Sales.Pricing;

codeunit 82501 "BeDyn Property Price Mgt."
{
    // Los precios provienen de la tabla de precios de venta (Sales Price) del producto
    // vinculado a la propiedad, filtrados por producto y variante: la variante identifica
    // la subpropiedad y la unidad de medida la base de precio (noche o mes) según la
    // configuración. Solo se consideran precios para "Todos los clientes" en divisa local.
    // Especificidad: variante+UM > variante > UM > línea genérica; dentro de cada
    // nivel gana la línea vigente con la fecha de inicio más reciente.
    procedure GetPrice(PropertyNo: Code[20]; RoomNo: Code[20]; PriceBasis: Enum "BeDyn Price Basis"; PriceDate: Date; var Price: Decimal): Boolean
    var
        Property: Record "BeDyn Property";
        PropertyRoom: Record "BeDyn Property Room";
        VariantCode: Code[10];
        UnitOfMeasureCode: Code[10];
    begin
        Price := 0;
        if not Property.Get(PropertyNo) then
            exit(false);
        if Property."Item No." = '' then
            exit(false);

        VariantCode := '';
        if RoomNo <> '' then
            if PropertyRoom.Get(PropertyNo, RoomNo) then
                VariantCode := PropertyRoom."Variant Code";
        UnitOfMeasureCode := GetUnitOfMeasureCode(PriceBasis);

        if VariantCode <> '' then begin
            if (UnitOfMeasureCode <> '') and FindPrice(Property."Item No.", VariantCode, UnitOfMeasureCode, PriceDate, Price) then
                exit(true);
            if FindPrice(Property."Item No.", VariantCode, '', PriceDate, Price) then
                exit(true);
        end;
        if (UnitOfMeasureCode <> '') and FindPrice(Property."Item No.", '', UnitOfMeasureCode, PriceDate, Price) then
            exit(true);
        exit(FindPrice(Property."Item No.", '', '', PriceDate, Price));
    end;

    procedure GetUnitOfMeasureCode(PriceBasis: Enum "BeDyn Price Basis"): Code[10]
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
    begin
        PropertySetup.GetInstance();
        case PriceBasis of
            PriceBasis::"Per Night":
                exit(PropertySetup."Night Unit of Measure Code");
            PriceBasis::"Per Month":
                exit(PropertySetup."Month Unit of Measure Code");
        end;
    end;

    procedure CalcRentalAmount(Reservation: Record "BeDyn Reservation"): Decimal
    begin
        case Reservation."Price Basis" of
            Reservation."Price Basis"::"Per Night":
                exit(CalcNightlyAmount(Reservation));
            Reservation."Price Basis"::"Per Month":
                exit(CalcMonthlyAmount(Reservation));
        end;
    end;

    local procedure FindPrice(ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; PriceDate: Date; var Price: Decimal): Boolean
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetRange("Item No.", ItemNo);
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"All Customers");
        SalesPrice.SetRange("Variant Code", VariantCode);
        SalesPrice.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        SalesPrice.SetRange("Currency Code", '');
        SalesPrice.SetFilter("Minimum Quantity", '<=%1', 1);
        SalesPrice.SetFilter("Starting Date", '<=%1', PriceDate);
        SalesPrice.SetFilter("Ending Date", '%1|>=%2', 0D, PriceDate);
        if not SalesPrice.FindLast() then
            exit(false);
        Price := SalesPrice."Unit Price";
        exit(true);
    end;

    local procedure CalcNightlyAmount(Reservation: Record "BeDyn Reservation") Amount: Decimal
    var
        NightDate: Date;
        NightPrice: Decimal;
    begin
        NightDate := Reservation."Start Date";
        while NightDate < Reservation."End Date" do begin
            if GetPrice(Reservation."Property No.", Reservation."Room No.", Reservation."Price Basis", NightDate, NightPrice) then
                Amount += NightPrice;
            NightDate += 1;
        end;
    end;

    // Por meses naturales: mes completo al precio vigente al inicio del mes; los meses
    // parciales de entrada y salida se prorratean a razón de precio mensual / 30.
    // Es el mismo criterio que usa la facturación mensual, de forma que el importe de la
    // reserva coincide con la suma de sus facturas.
    local procedure CalcMonthlyAmount(Reservation: Record "BeDyn Reservation") Amount: Decimal
    var
        ChunkStart: Date;
        ChunkEnd: Date;
        LastNight: Date;
    begin
        ChunkStart := Reservation."Start Date";
        LastNight := Reservation."End Date" - 1;
        while ChunkStart <= LastNight do begin
            ChunkEnd := CalcDate('<CM>', ChunkStart);
            if ChunkEnd > LastNight then
                ChunkEnd := LastNight;
            Amount += CalcCalendarPeriodAmount(Reservation."Property No.", Reservation."Room No.", ChunkStart, ChunkEnd);
            ChunkStart := ChunkEnd + 1;
        end;
    end;

    // Importe de un periodo dentro de un mismo mes natural (ambas fechas incluidas, la
    // fecha de fin es la última noche ocupada). Mes natural completo = precio mensual;
    // periodo parcial = días × precio mensual / 30.
    procedure CalcCalendarPeriodAmount(PropertyNo: Code[20]; RoomNo: Code[20]; PeriodStart: Date; LastNight: Date) Amount: Decimal
    var
        PriceBasis: Enum "BeDyn Price Basis";
        MonthlyPrice: Decimal;
    begin
        if not GetPrice(PropertyNo, RoomNo, PriceBasis::"Per Month", PeriodStart, MonthlyPrice) then
            exit(0);
        if (Date2DMY(PeriodStart, 1) = 1) and (LastNight = CalcDate('<CM>', PeriodStart)) then
            exit(MonthlyPrice);
        exit(Round(MonthlyPrice * (LastNight - PeriodStart + 1) / 30, 0.01));
    end;
}
