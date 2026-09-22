namespace BeDynamic.PortalImport;

using Microsoft.Inventory.Item;

codeunit 82601 "BeDyn Portal Validation"
{
    // Validación de las líneas importadas antes de contabilizar:
    //   - Reserva (ambos canales): código de reserva, alojamiento mapeado (propiedad),
    //     bruto distinto de cero, producto de la propiedad (y su variante por defecto),
    //     configuración de ventas y comisiones, y coherencia de importes.
    //     Booking además: solo estado OK (cancelaciones y ajustes se omiten).
    //   - Payout: identificador del payout, importe cobrado, banco del canal y cliente
    //     genérico. Booking además: conciliación con la suma de las reservas del grupo.
    //   - Ajuste de resolución (Airbnb) y tipo Otro: se validan como una reserva (el
    //     bruto puede venir vacío y en Otro el código de reserva es opcional) y se
    //     contabilizan como factura o abono según el signo.

    procedure ValidateBatch(BatchCode: Code[20])
    var
        Buffer: Record "BeDyn Portal Import Buffer";
    begin
        Buffer.SetCurrentKey("Batch Code", Status);
        Buffer.SetRange("Batch Code", BatchCode);
        ValidateLines(Buffer);
    end;

    procedure ValidateLines(var BufferSel: Record "BeDyn Portal Import Buffer")
    begin
        if BufferSel.FindSet() then
            repeat
                ValidateLine(BufferSel);
            until BufferSel.Next() = 0;
    end;

    local procedure ValidateLine(var Buffer: Record "BeDyn Portal Import Buffer")
    var
        Setup: Record "BeDyn Portal Setup";
        ErrText: Text;
        WarnText: Text;
        UnsupportedTypeLbl: Label 'Tipo de movimiento no soportado: revísalo y contabilízalo manualmente si procede.';
        PayoutSkipLbl: Label 'Payout: omitido (activar "Contabilizar payouts" en la configuración para contabilizarlo).';
        NotOkStatusLbl: Label 'Reserva con estado "%1": cancelaciones y ajustes están fuera de alcance, revísala manualmente.', Comment = '%1 = estado de la reserva en el CSV';
    begin
        // Las líneas ya registradas no se tocan.
        if Buffer.Status = Buffer.Status::Posted then
            exit;

        Setup.GetSetup();
        ErrText := '';
        WarnText := '';
        Buffer."Error Message" := '';
        Buffer."Warning Message" := '';

        case Buffer."Row Type" of
            Buffer."Row Type"::Reservation,
            Buffer."Row Type"::Adjustment,
            Buffer."Row Type"::Other:
                begin
                    if SkipByReservationStatus(Buffer, Setup) then begin
                        Buffer.SetSkippedState(StrSubstNo(NotOkStatusLbl, Buffer."Reservation Status"));
                        exit;
                    end;
                    ValidateReservation(Buffer, Setup, ErrText, WarnText);
                end;
            Buffer."Row Type"::Payout:
                begin
                    if not Setup."Process Payouts" then begin
                        Buffer.SetSkippedState(PayoutSkipLbl);
                        exit;
                    end;
                    ValidatePayout(Buffer, Setup, ErrText, WarnText);
                end;
            else begin
                Buffer.SetSkippedState(UnsupportedTypeLbl);
                exit;
            end;
        end;

        ValidateCommon(Buffer, Setup, ErrText);

        Buffer."Warning Message" := CopyStr(WarnText, 1, MaxStrLen(Buffer."Warning Message"));
        if ErrText <> '' then begin
            Buffer.SetErrorState(ErrText);
            exit;
        end;
        Buffer.Status := Buffer.Status::Validated;
        Buffer.Modify(true);
    end;

    // Solo se procesan las reservas de Booking en estado OK; las canceladas también
    // si está activo "Contabilizar reservas canceladas" (se facturan como una OK).
    // El resto de estados se omite para revisión manual.
    local procedure SkipByReservationStatus(var Buffer: Record "BeDyn Portal Import Buffer"; Setup: Record "BeDyn Portal Setup"): Boolean
    var
        StatusUpper: Text;
    begin
        if (Buffer.Channel <> Buffer.Channel::Booking) or (Buffer."Row Type" <> Buffer."Row Type"::Reservation) then
            exit(false);
        StatusUpper := UpperCase(Buffer."Reservation Status");
        if StatusUpper = 'OK' then
            exit(false);
        // "Cancelada"/"Cancelado"/"Cancelled" según el export.
        if StatusUpper.StartsWith('CANCEL') and Setup."Process Cancelled Reservations" then
            exit(false);
        exit(true);
    end;

    local procedure ValidateCommon(var Buffer: Record "BeDyn Portal Import Buffer"; Setup: Record "BeDyn Portal Setup"; var ErrText: Text)
    var
        NoDateErr: Label 'Falta la fecha del movimiento.';
        CurrencyErr: Label 'Divisa no soportada (%1): solo se admite EUR.', Comment = '%1 = código de divisa del CSV';
        NoChannelValueErr: Label 'La dimensión de canal está configurada sin valor para %1: indícalo en la configuración.', Comment = '%1 = canal';
    begin
        if Buffer."Transaction Date" = 0D then
            AddText(ErrText, NoDateErr);
        if not (UpperCase(Buffer."Currency Code") in ['', 'EUR']) then
            AddText(ErrText, StrSubstNo(CurrencyErr, Buffer."Currency Code"));
        if (Setup."Channel Dimension Code" <> '') and (Setup.GetChannelDimValue(Buffer.Channel) = '') then
            AddText(ErrText, StrSubstNo(NoChannelValueErr, Buffer.Channel));
    end;

    local procedure ValidateReservation(var Buffer: Record "BeDyn Portal Import Buffer"; Setup: Record "BeDyn Portal Setup"; var ErrText: Text; var WarnText: Text)
    var
        NoReservationCodeErr: Label 'Falta el código de la reserva.';
        NoListingErr: Label 'Falta el alojamiento.';
        ZeroAmountErr: Label 'El importe neto de la reserva es cero.';
        ZeroGrossErr: Label 'El importe bruto de la reserva es cero: no se puede facturar.';
        NoCustomerErr: Label 'Falta el cliente genérico en la configuración.';
        NoVatGroupErr: Label 'Falta el grupo IVA producto de ventas en la configuración (los importes vienen con IVA incluido).';
        NoItemErr: Label 'No existe ningún producto con el código %1: la propiedad se factura como producto y debe existir un producto con el mismo código que el valor de dimensión.', Comment = '%1 = código propiedad';
        NoVariantErr: Label 'El producto %1 no tiene la variante %2 indicada como variante por defecto en la configuración: créala en el producto, activa "Auto-crear variante por defecto" o vacía el campo de la configuración.', Comment = '%1 = código propiedad, %2 = código variante';
        NoFeeAccountErr: Label 'Falta la cuenta de comisiones en la configuración (necesaria en modo cuenta contable).';
        NoVendorErr: Label 'Falta el proveedor de %1 en la configuración (necesario en modo cargo a proveedor).', Comment = '%1 = canal';
        AirbnbMismatchLbl: Label 'Los importes no cuadran: neto %1 + comisiones %2 <> bruto %3.', Comment = '%1 = importe neto, %2 = comisiones, %3 = ingresos brutos';
        BookingMismatchLbl: Label 'Los importes no cuadran: bruto %1 + comisiones/IVA %2 <> neto %3.', Comment = '%1 = bruto, %2 = comisiones + cargo + IVA + impuestos (negativos), %3 = neto';
    begin
        // En el tipo Otro el código de reserva es opcional (el nº de documento se
        // genera al contabilizar si falta).
        if (Buffer."Reservation Code" = '') and (Buffer."Row Type" <> Buffer."Row Type"::Other) then
            AddText(ErrText, NoReservationCodeErr);

        if Buffer.GetListingKey() = '' then
            AddText(ErrText, NoListingErr)
        else
            ResolveListing(Buffer, Setup, ErrText);

        if Buffer.Amount = 0 then
            AddText(ErrText, ZeroAmountErr);
        // En los ajustes de resolución el bruto puede venir vacío: se reconstruye
        // desde el neto y las comisiones al contabilizar.
        if (Buffer."Gross Amount" = 0) and (Buffer."Row Type" = Buffer."Row Type"::Reservation) then
            AddText(ErrText, ZeroGrossErr);
        if Setup."Generic Customer No." = '' then
            AddText(ErrText, NoCustomerErr);
        if Setup."Sales VAT Prod. Posting Group" = '' then
            AddText(ErrText, NoVatGroupErr);
        CheckPropertyItem(Buffer, Setup, ErrText, NoItemErr, NoVariantErr);
        if (Buffer."Commission Amount" <> 0) or (Buffer."Payment Fee Amount" <> 0) or (Buffer."VAT Fee Amount" <> 0) then begin
            case Setup."Commission Treatment" of
                Setup."Commission Treatment"::Vendor:
                    if Setup.GetVendorNo(Buffer.Channel) = '' then
                        AddText(ErrText, StrSubstNo(NoVendorErr, Buffer.Channel));
                Setup."Commission Treatment"::"G/L Account":
                    if Setup."Commission G/L Account" = '' then
                        AddText(ErrText, NoFeeAccountErr);
            end;
            CheckPaymentJournal(Setup, ErrText);
        end;

        // Coherencia del CSV, con la aritmética de signos de cada canal.
        case Buffer.Channel of
            // Airbnb: neto + comisiones (positivas) = bruto (tolerancia de céntimo).
            Buffer.Channel::Airbnb:
                if (Buffer."Gross Amount" <> 0) and
                   (Abs(Buffer.Amount + Buffer."Commission Amount" + Buffer."Payment Fee Amount" - Buffer."Gross Amount") > 0.01)
                then
                    AddText(WarnText, StrSubstNo(AirbnbMismatchLbl, Buffer.Amount, Buffer."Commission Amount" + Buffer."Payment Fee Amount", Buffer."Gross Amount"));
            // Booking: bruto + comisión + cargo + IVA + impuestos (negativos) = neto.
            Buffer.Channel::Booking:
                if Abs(Buffer."Gross Amount" + Buffer."Commission Amount" + Buffer."Payment Fee Amount" +
                       Buffer."VAT Fee Amount" + Buffer."Taxes Amount" - Buffer.Amount) > 0.02
                then
                    AddText(WarnText, StrSubstNo(BookingMismatchLbl,
                        Buffer."Gross Amount",
                        Buffer."Commission Amount" + Buffer."Payment Fee Amount" + Buffer."VAT Fee Amount" + Buffer."Taxes Amount",
                        Buffer.Amount));
        end;
    end;

    local procedure ValidatePayout(var Buffer: Record "BeDyn Portal Import Buffer"; Setup: Record "BeDyn Portal Setup"; var ErrText: Text; var WarnText: Text)
    var
        NoReferenceErr: Label 'Falta el código de referencia del payout.';
        NoGroupErr: Label 'Falta el identificador del grupo de payout ("Descripción del cargo").';
        ZeroPaidOutErr: Label 'El importe cobrado del payout es cero.';
        NoBankErr: Label 'Falta el banco de los payouts de %1 en la configuración.', Comment = '%1 = canal';
        NoCustomerErr: Label 'Falta el cliente genérico en la configuración.';
        NoReservationsLbl: Label 'No hay reservas del grupo en la hoja de importación.';
        GroupMismatchLbl: Label 'El payout (%1) no cuadra con la suma de sus reservas (%2).', Comment = '%1 = importe del pago, %2 = suma de los netos de las reservas del grupo';
    begin
        case Buffer.Channel of
            Buffer.Channel::Airbnb:
                if Buffer."Reference Code" = '' then
                    AddText(ErrText, NoReferenceErr);
            Buffer.Channel::Booking:
                begin
                    if Buffer."Payout Group ID" = '' then
                        AddText(ErrText, NoGroupErr);
                    // La propiedad del payout (para la dimensión del asiento), si viene.
                    if Buffer.GetListingKey() <> '' then
                        ResolveListing(Buffer, Setup, ErrText);
                    CheckGroupReconciliation(Buffer, WarnText, NoReservationsLbl, GroupMismatchLbl);
                end;
        end;
        if Buffer."Paid Out Amount" = 0 then
            AddText(ErrText, ZeroPaidOutErr);
        if Setup.GetPayoutBankAccount(Buffer.Channel) = '' then
            AddText(ErrText, StrSubstNo(NoBankErr, Buffer.Channel));
        if Setup."Generic Customer No." = '' then
            AddText(ErrText, NoCustomerErr);
        CheckPaymentJournal(Setup, ErrText);
    end;

    // Con el registro automático ("Post Automatically" de Recurring Invoicing)
    // desactivado, los pagos se dejan en un diario: debe estar configurado.
    local procedure CheckPaymentJournal(Setup: Record "BeDyn Portal Setup"; var ErrText: Text)
    var
        NoJournalErr: Label 'Registro automático desactivado: indica el libro diario y la sección de pagos en la configuración de portales.';
    begin
        if Setup.AutoPostEnabled() then
            exit;
        if (Setup."Payment Journal Template" = '') or (Setup."Payment Journal Batch" = '') then
            AddText(ErrText, NoJournalErr);
    end;

    // Conciliación del payout de Booking con sus reservas: la suma de los netos de
    // las reservas del grupo debe coincidir con el pago (±0,02 por redondeos).
    local procedure CheckGroupReconciliation(var Buffer: Record "BeDyn Portal Import Buffer"; var WarnText: Text; NoReservationsLbl: Text; GroupMismatchLbl: Text)
    var
        Res: Record "BeDyn Portal Import Buffer";
    begin
        if Buffer."Payout Group ID" = '' then
            exit;
        Res.SetCurrentKey("Payout Group ID", "Row Type");
        Res.SetRange("Payout Group ID", Buffer."Payout Group ID");
        Res.SetRange("Row Type", Res."Row Type"::Reservation);
        if Res.IsEmpty() then begin
            AddText(WarnText, NoReservationsLbl);
            exit;
        end;
        Res.CalcSums(Amount);
        if Abs(Res.Amount - Buffer."Paid Out Amount") > 0.02 then
            AddText(WarnText, StrSubstNo(GroupMismatchLbl, Buffer."Paid Out Amount", Res.Amount));
    end;

    // Resuelve la propiedad desde el mapeo de alojamientos del portal del canal.
    // Solo rellena los campos vacíos, para respetar correcciones manuales.
    local procedure ResolveListing(var Buffer: Record "BeDyn Portal Import Buffer"; Setup: Record "BeDyn Portal Setup"; var ErrText: Text)
    var
        Mapping: Record "BeDyn Portal Listing Mapping";
        ChannelMgt: Codeunit "BeDyn Portal Channel Mgt.";
        PortalCode: Code[20];
        NotMappedErr: Label 'Alojamiento sin mapear: complétalo en el mapeo de alojamientos y revalida.';
        NoPropertyErr: Label 'El mapeo del alojamiento no tiene código de propiedad.';
        NoPortalErr: Label 'Ningún portal del maestro tiene el canal de importación %1: asígnalo en la lista de Portales y revalida.', Comment = '%1 = canal';
    begin
        // El portal del canal: con auto-alta de mapeos activo se crea si no existe.
        if Setup."Auto Create Listing Mapping" then
            PortalCode := ChannelMgt.EnsurePortal(Buffer.Channel)
        else
            PortalCode := ChannelMgt.FindPortalCode(Buffer.Channel);
        if PortalCode = '' then begin
            AddText(ErrText, StrSubstNo(NoPortalErr, Buffer.Channel));
            exit;
        end;

        if not Mapping.Get(PortalCode, Buffer.GetListingKey()) then begin
            if Setup."Auto Create Listing Mapping" then begin
                Mapping.Init();
                Mapping."Portal Code" := PortalCode;
                Mapping."Listing Key" := Buffer.GetListingKey();
                Mapping."Listing Name" := Buffer.Listing;
                Mapping.Insert(true);
            end;
            AddText(ErrText, NotMappedErr);
            exit;
        end;

        // Mantener el nombre del mapeo al día (informativo).
        if (Mapping."Listing Name" = '') and (Buffer.Listing <> '') then begin
            Mapping."Listing Name" := Buffer.Listing;
            Mapping.Modify(true);
        end;

        if Buffer."Property Code" = '' then
            Buffer."Property Code" := Mapping."Property Code";
        if Buffer."Property Code" = '' then
            AddText(ErrText, NoPropertyErr);
        // La variante del mapeo solo aplica si la línea sigue con la propiedad mapeada.
        if (Buffer."Variant Code" = '') and (Buffer."Property Code" = Mapping."Property Code") then
            Buffer."Variant Code" := Mapping."Variant Code";
    end;

    // La propiedad se factura como producto: debe existir un producto con el mismo
    // código que el valor de dimensión de la propiedad y, si la línea/mapeo o la
    // configuración indican una variante, el producto debe tenerla (con
    // "Auto-crear variante por defecto" activo, se crea aquí si falta).
    local procedure CheckPropertyItem(var Buffer: Record "BeDyn Portal Import Buffer"; Setup: Record "BeDyn Portal Setup"; var ErrText: Text; NoItemErr: Text; NoVariantErr: Text)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        VariantCode: Code[10];
    begin
        if Buffer."Property Code" = '' then
            exit;
        if not Item.Get(Buffer."Property Code") then begin
            AddText(ErrText, StrSubstNo(NoItemErr, Buffer."Property Code"));
            exit;
        end;
        EnsureItemUoM(Item, Setup.GetSalesUoMCode(Buffer.Channel));
        VariantCode := Buffer.GetEffectiveVariantCode(Setup."Default Variant Code");
        if VariantCode = '' then
            exit;
        if ItemVariant.Get(Buffer."Property Code", VariantCode) then
            exit;
        if Setup."Auto Create Default Variant" then begin
            CreateDefaultVariant(Item, VariantCode);
            exit;
        end;
        AddText(ErrText, StrSubstNo(NoVariantErr, Buffer."Property Code", VariantCode));
    end;

    // La unidad de medida de ventas configurada para el canal debe existir en el
    // producto de la propiedad: se crea con factor 1 si falta (solo maestro, sin
    // impacto contable).
    local procedure EnsureItemUoM(Item: Record Item; UoMCode: Code[10])
    var
        ItemUoM: Record "Item Unit of Measure";
    begin
        if UoMCode = '' then
            exit;
        if ItemUoM.Get(Item."No.", UoMCode) then
            exit;
        ItemUoM.Init();
        ItemUoM."Item No." := Item."No.";
        ItemUoM.Validate(Code, UoMCode);
        ItemUoM.Validate("Qty. per Unit of Measure", 1);
        ItemUoM.Insert(true);
    end;

    // Crea la variante por defecto en el producto de la propiedad, con la misma
    // convención de descripción que el asistente de creación ("Dirección - H0").
    local procedure CreateDefaultVariant(Item: Record Item; VariantCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
        VariantDescLbl: Label '%1 - %2', Comment = '%1 = descripción producto, %2 = código variante', Locked = true;
    begin
        ItemVariant.Init();
        ItemVariant."Item No." := Item."No.";
        ItemVariant.Code := VariantCode;
        ItemVariant.Description := CopyStr(StrSubstNo(VariantDescLbl, Item.Description, VariantCode), 1, MaxStrLen(ItemVariant.Description));
        ItemVariant.Insert(true);
    end;

    local procedure AddText(var Target: Text; NewText: Text)
    begin
        if Target <> '' then
            Target += ' ';
        Target += NewText;
    end;
}
