namespace BeDynamic.PortalImport;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;

codeunit 82602 "BeDyn Portal Import Process"
{
    // Contabilización de las líneas validadas de cualquier canal, en la fecha del
    // movimiento y con las dimensiones de propiedad y canal (modelo Airbnb):
    //
    //   Reserva:
    //     · Factura de venta al cliente genérico por el importe bruto (IVA incluido,
    //       el grupo IVA del setup calcula la base hacia atrás). Una línea de producto
    //       cuyo código es el de la propiedad, con la estancia en la descripción. El
    //       código de la reserva va como nº de documento externo.
    //     · Comisiones del canal (comisión + comisión de pagos + IVA retenido en
    //       Booking): se descuentan de la factura del cliente con un diario aplicado a
    //       ella — abono al cliente y, según configuración, cargo al proveedor del
    //       canal (pago a cuenta pendiente de netear con su factura real) o a la
    //       cuenta de comisiones (con el IVA en su propia cuenta si está configurada).
    //       El cliente queda pendiente solo del neto que el canal transfiere.
    //
    //   Ajuste de resolución (Airbnb) y tipo Otro: mismo esquema que la reserva pero
    //   con abono de venta cuando el importe es negativo y la comisión con el signo
    //   invertido. Si el bruto viene vacío, se reconstruye desde el neto y las
    //   comisiones (neto + comisiones = bruto). En Otro, sin código de reserva se
    //   genera el nº de documento a partir de la línea.
    //
    //   Payout: cargo al banco del canal y abono al cliente genérico (pago a cuenta,
    //   sin aplicar). Solo si "Contabilizar payouts" está activo.
    //
    // Registro automático: con "Post Automatically" (Recurring Invoicing Setup)
    // activo, factura y diarios se registran directamente; desactivado, la factura
    // queda en borrador y las líneas de diario (comisiones y payouts) se dejan en el
    // diario/sección de pagos configurados, sin aplicación, para registro manual.
    //
    // Reintentos: cada paso deja marca en el buffer ("Created Invoice No.", "Income
    // Posted", "Commission Posted") para no duplicar documentos ni asientos al
    // reprocesar una línea que falló a medias.

    var
        Setup: Record "BeDyn Portal Setup";
        AutoPost: Boolean;

    procedure ProcessLines(var BufferParam: Record "BeDyn Portal Import Buffer")
    var
        Buffer: Record "BeDyn Portal Import Buffer";
        DoneCount: Integer;
        ErrorCount: Integer;
        NothingMsg: Label 'No hay líneas validadas pendientes de procesar en el filtro actual.';
        DoneMsg: Label 'Proceso terminado: %1 líneas procesadas correctamente, %2 con error.', Comment = '%1, %2 = contadores';
    begin
        Setup.GetSetup();
        Setup.TestField("Generic Customer No.");
        AutoPost := Setup.AutoPostEnabled();
        if not AutoPost then begin
            Setup.TestField("Payment Journal Template");
            Setup.TestField("Payment Journal Batch");
        end;

        Buffer.Copy(BufferParam);
        Buffer.SetRange(Status, Buffer.Status::Validated);
        if not Buffer.FindSet(true) then begin
            Message(NothingMsg);
            exit;
        end;
        repeat
            if ProcessLine(Buffer) then
                DoneCount += 1
            else
                ErrorCount += 1;
        until Buffer.Next() = 0;

        Message(DoneMsg, DoneCount, ErrorCount);
    end;

    local procedure ProcessLine(var Buffer: Record "BeDyn Portal Import Buffer"): Boolean
    begin
        case Buffer."Row Type" of
            Buffer."Row Type"::Reservation,
            Buffer."Row Type"::Adjustment,
            Buffer."Row Type"::Other:
                exit(ProcessReservation(Buffer));
            Buffer."Row Type"::Payout:
                exit(ProcessPayout(Buffer));
        end;
        exit(false);
    end;

    // Bruto de la línea; en los ajustes puede venir vacío y se reconstruye con la
    // identidad del CSV de Airbnb: neto + comisiones = bruto.
    local procedure GetGrossBase(var Buffer: Record "BeDyn Portal Import Buffer"): Decimal
    begin
        if Buffer."Gross Amount" <> 0 then
            exit(Buffer."Gross Amount");
        exit(Buffer.Amount + Buffer."Commission Amount" + Buffer."Payment Fee Amount");
    end;

    // Los ajustes de resolución y los movimientos de tipo Otro negativos se
    // registran como abono de venta; el resto, como factura.
    local procedure GetDocumentType(var Buffer: Record "BeDyn Portal Import Buffer"): Enum "Sales Document Type"
    begin
        if (Buffer."Row Type" in [Buffer."Row Type"::Adjustment, Buffer."Row Type"::Other]) and (GetGrossBase(Buffer) < 0) then
            exit("Sales Document Type"::"Credit Memo");
        exit("Sales Document Type"::Invoice);
    end;

    // Nº de documento para los diarios de la reserva: el código de reserva o, si
    // falta (tipo Otro), uno generado a partir de la línea.
    local procedure GetDocumentNo(var Buffer: Record "BeDyn Portal Import Buffer"): Code[20]
    begin
        if Buffer."Reservation Code" <> '' then
            exit(Buffer."Reservation Code");
        exit(CopyStr(GetChannelPrefix(Buffer.Channel) + Format(Buffer."Entry No."), 1, 20));
    end;

    // ============================ RESERVAS ============================

    local procedure ProcessReservation(var Buffer: Record "BeDyn Portal Import Buffer"): Boolean
    var
        SalesHeader: Record "Sales Header";
        DocType: Enum "Sales Document Type";
        PostedDocNo: Code[20];
        FeeAmount: Decimal;
        PostErr: Label 'Error al registrar el documento de la reserva %1: %2', Comment = '%1 = cód. reserva, %2 = error';
        FeeErr: Label 'Error al descontar la comisión de la reserva %1: %2', Comment = '%1 = cód. reserva, %2 = error';
    begin
        DocType := GetDocumentType(Buffer);

        // 1) Factura (o abono, en ajustes negativos) al cliente genérico.
        if not Buffer."Income Posted" then begin
            // Reutilizar el borrador de un intento anterior si sigue existiendo.
            if (Buffer."Created Invoice No." = '') or
               (not SalesHeader.Get(DocType, Buffer."Created Invoice No."))
            then begin
                if not TryCreateSalesDocument(SalesHeader, Buffer, DocType) then begin
                    CleanupHalfCreatedDoc(SalesHeader);
                    Buffer.SetErrorState(GetLastErrorText());
                    exit(false);
                end;
                Buffer."Created Invoice No." := SalesHeader."No.";
                Buffer.Modify(true);
            end else
                // Un borrador de un intento anterior puede haberse creado con otra
                // configuración (sin variante, sin unidad de medida en noches...):
                // se refrescan sus líneas como si se creara ahora.
                if not TryRefreshDraftLines(SalesHeader, Buffer) then begin
                    Buffer.SetErrorState(GetLastErrorText());
                    exit(false);
                end;

            if AutoPost then begin
                if not PostSalesDocument(SalesHeader, PostedDocNo) then begin
                    Buffer.SetErrorState(StrSubstNo(PostErr, Buffer."Reservation Code", GetLastErrorText()));
                    exit(false);
                end;
                Buffer."Income Posted" := true;
                Buffer."Created Invoice No." := '';
                Buffer."Posted Document No." := PostedDocNo;
            end else
                // Registro automático desactivado: el documento queda en borrador
                // ("Created Invoice No.") y se referencia como resultado de la línea.
                Buffer."Posted Document No." := SalesHeader."No.";
            Buffer.Modify(true);
        end;

        // 2) Comisiones del canal: descuento sobre la factura del cliente, contra el
        //    proveedor (o la cuenta de comisiones). El cliente queda pendiente del
        //    neto. En los abonos, con el signo invertido.
        FeeAmount := Abs(Buffer."Commission Amount") + Abs(Buffer."Payment Fee Amount") + Abs(Buffer."VAT Fee Amount");
        if (not Buffer."Commission Posted") and (FeeAmount <> 0) then begin
            Commit();
            if not TryPostCommission(Buffer, FeeAmount, DocType) then begin
                Buffer.SetErrorState(StrSubstNo(FeeErr, Buffer."Reservation Code", GetLastErrorText()));
                exit(false);
            end;
            Buffer."Commission Posted" := true;
            Buffer.Modify(true);
        end;

        Buffer.Status := Buffer.Status::Posted;
        Buffer."Error Message" := '';
        Buffer.Modify(true);
        exit(true);
    end;

    [TryFunction]
    local procedure TryCreateSalesDocument(var SalesHeader: Record "Sales Header"; var Buffer: Record "BeDyn Portal Import Buffer"; DocType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        VariantCode: Code[10];
    begin
        EnsureDimensionValue(Buffer);

        SalesHeader.Init();
        SalesHeader."Document Type" := DocType;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", Setup."Generic Customer No.");
        SalesHeader.Validate("Document Date", Buffer."Transaction Date");
        SalesHeader.Validate("Posting Date", Buffer."Transaction Date");
        // Los importes de los portales vienen con IVA incluido: BC calcula la base hacia atrás.
        SalesHeader.Validate("Prices Including VAT", true);
        // El código de la reserva, como nº de documento externo de la factura.
        SalesHeader.Validate("External Document No.", Buffer."Reservation Code");
        ApplyHeaderDimensions(SalesHeader, Buffer);
        SalesHeader.Modify(true);

        // La propiedad se factura como producto: código de producto = código de propiedad.
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine."Line No." := 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Buffer."Property Code");
        VariantCode := Buffer.GetEffectiveVariantCode(Setup."Default Variant Code");
        if VariantCode <> '' then
            SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Validate("VAT Prod. Posting Group", Setup."Sales VAT Prod. Posting Group");
        ApplyLineQuantityAndPrice(SalesLine, Buffer);
        SalesLine.Validate(Description,
            CopyStr(BuildInvoiceLineDescription(Buffer), 1, MaxStrLen(SalesLine.Description)));
        SalesLine.Modify(true);
    end;

    // Cantidad e importes de la línea: con noches informadas, cantidad = noches (en
    // la unidad de medida configurada para el canal) y precio = bruto / noches, de
    // modo que la factura detalla el precio/noche. El importe de la línea se fuerza
    // al bruto exacto para que el total no varíe por el redondeo del precio
    // unitario. Sin noches, cantidad 1 con el bruto como precio, como antes.
    local procedure ApplyLineQuantityAndPrice(var SalesLine: Record "Sales Line"; var Buffer: Record "BeDyn Portal Import Buffer")
    var
        GrossBase: Decimal;
        UoMCode: Code[10];
    begin
        GrossBase := Abs(GetGrossBase(Buffer));
        UoMCode := Setup.GetSalesUoMCode(Buffer.Channel);
        if UoMCode <> '' then begin
            // La unidad puede no existir aún en el producto si la línea se validó
            // antes de configurarla (al revalidar la crea la validación).
            EnsureItemUoM(SalesLine."No.", UoMCode);
            SalesLine.Validate("Unit of Measure Code", UoMCode);
        end;
        if Buffer.Nights > 0 then begin
            SalesLine.Validate(Quantity, Buffer.Nights);
            SalesLine.Validate("Unit Price", GrossBase / Buffer.Nights);
        end else begin
            SalesLine.Validate(Quantity, 1);
            SalesLine.Validate("Unit Price", GrossBase);
        end;
        if SalesLine."Line Amount" <> GrossBase then
            SalesLine.Validate("Line Amount", GrossBase);
    end;

    // Alta de la unidad de medida en el producto con factor 1 si falta (solo
    // maestro, sin impacto contable); mismo criterio que la validación.
    local procedure EnsureItemUoM(ItemNo: Code[20]; UoMCode: Code[10])
    var
        ItemUoM: Record "Item Unit of Measure";
    begin
        if ItemUoM.Get(ItemNo, UoMCode) then
            exit;
        ItemUoM.Init();
        ItemUoM."Item No." := ItemNo;
        ItemUoM.Validate(Code, UoMCode);
        ItemUoM.Validate("Qty. per Unit of Measure", 1);
        ItemUoM.Insert(true);
    end;

    // Refresca las líneas de producto de un borrador reutilizado de un intento
    // anterior: completa la variante si falta (p.ej. si se configuró después) y
    // vuelve a aplicar cantidad, precios y descripción, para que un borrador creado
    // con una configuración anterior (p.ej. sin la unidad en noches) quede igual
    // que uno recién creado. Validar la variante recalcula precio y descripción,
    // así que se aplican siempre después.
    [TryFunction]
    local procedure TryRefreshDraftLines(var SalesHeader: Record "Sales Header"; var Buffer: Record "BeDyn Portal Import Buffer")
    var
        SalesLine: Record "Sales Line";
        VariantCode: Code[10];
    begin
        VariantCode := Buffer.GetEffectiveVariantCode(Setup."Default Variant Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if not SalesLine.FindSet(true) then
            exit;
        repeat
            if (VariantCode <> '') and (SalesLine."Variant Code" = '') then
                SalesLine.Validate("Variant Code", VariantCode);
            ApplyLineQuantityAndPrice(SalesLine, Buffer);
            SalesLine.Validate(Description,
                CopyStr(BuildInvoiceLineDescription(Buffer), 1, MaxStrLen(SalesLine.Description)));
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    // Descripción de la línea con los datos de la estancia:
    // "4 noches del 30/05/2026 - 03/06/2026 Tereza Trunečková".
    // Sin viajero (Booking) se usa el alojamiento; si faltan fechas o noches,
    // canal + código de reserva + viajero/alojamiento.
    local procedure BuildInvoiceLineDescription(var Buffer: Record "BeDyn Portal Import Buffer"): Text
    var
        StayLbl: Label '%1 noches del %2 - %3 %4', Comment = '%1 = noches, %2 = fecha inicio, %3 = fecha fin, %4 = viajero o alojamiento';
        StaySingularLbl: Label '1 noche del %1 - %2 %3', Comment = '%1 = fecha inicio, %2 = fecha fin, %3 = viajero o alojamiento';
        FallbackLbl: Label '%1 %2 %3', Comment = '%1 = canal, %2 = cód. reserva, %3 = viajero o alojamiento';
        AdjustmentLbl: Label 'Ajuste resolución %1', Comment = '%1 = descripción de la estancia';
        Desc: Text;
    begin
        // En el tipo Otro, el detalle del CSV describe el movimiento mejor que la estancia.
        if (Buffer."Row Type" = Buffer."Row Type"::Other) and (Buffer.Details <> '') then
            exit(Buffer.Details);
        if (Buffer."Start Date" = 0D) or (Buffer."End Date" = 0D) or (Buffer.Nights = 0) then
            Desc := StrSubstNo(FallbackLbl, Buffer.Channel, Buffer."Reservation Code", GetPartyText(Buffer))
        else
            if Buffer.Nights = 1 then
                Desc := StrSubstNo(StaySingularLbl, FormatStayDate(Buffer."Start Date"), FormatStayDate(Buffer."End Date"), GetPartyText(Buffer))
            else
                Desc := StrSubstNo(StayLbl, Buffer.Nights, FormatStayDate(Buffer."Start Date"), FormatStayDate(Buffer."End Date"), GetPartyText(Buffer));
        if Buffer."Row Type" = Buffer."Row Type"::Adjustment then
            Desc := StrSubstNo(AdjustmentLbl, Desc);
        exit(Desc);
    end;

    local procedure GetPartyText(var Buffer: Record "BeDyn Portal Import Buffer"): Text
    begin
        if Buffer.Guest <> '' then
            exit(Buffer.Guest);
        exit(Buffer.Listing);
    end;

    local procedure FormatStayDate(StayDate: Date): Text
    begin
        exit(Format(StayDate, 0, '<Day,2>/<Month,2>/<Year4>'));
    end;

    local procedure CleanupHalfCreatedDoc(var SalesHeader: Record "Sales Header")
    begin
        // Un TryFunction no revierte escrituras: si la creación falló a medias,
        // eliminar el borrador incompleto para no dejar basura.
        if SalesHeader."No." = '' then
            exit;
        if SalesHeader.Find() then
            SalesHeader.Delete(true);
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"; var PostedDocNo: Code[20]): Boolean
    var
        SalesPost: Codeunit "Sales-Post";
        SavedWorkDate: Date;
        PostOk: Boolean;
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        Commit();
        // Igualar temporalmente la fecha de trabajo a la de registro evita el aviso
        // "la fecha de registro es diferente de la fecha de trabajo".
        SavedWorkDate := WorkDate();
        if SalesHeader."Posting Date" <> 0D then
            WorkDate(SalesHeader."Posting Date");
        PostOk := SalesPost.Run(SalesHeader);
        WorkDate(SavedWorkDate);
        if not PostOk then
            exit(false);
        PostedDocNo := SalesHeader."Last Posting No.";
        if PostedDocNo = '' then
            PostedDocNo := SalesHeader."Posting No.";
        exit(true);
    end;

    // Descuento de las comisiones sobre la factura del cliente: abono al cliente
    // aplicado a la factura de la reserva y, de contrapartida, cargo al proveedor
    // del canal (pago a cuenta pendiente de su factura) o a la cuenta de comisiones
    // (con el IVA retenido de Booking en su propia cuenta si está configurada).
    // En los abonos (ajustes de resolución), las mismas patas con el signo invertido.
    //
    // BC no admite cliente contra proveedor en una sola línea de diario ("Tipo mov.
    // o Tipo contrapartida deben ser tipo Cuenta o Banco"), así que la compensación
    // se registra como líneas del mismo documento con la misma instancia del
    // registrador, que forman un único asiento equilibrado.
    [TryFunction]
    local procedure TryPostCommission(var Buffer: Record "BeDyn Portal Import Buffer"; FeeAmount: Decimal; DocType: Enum "Sales Document Type")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Sign: Integer;
        VatFee: Decimal;
        FeeDescLbl: Label 'Comisión %1 %2 %3', Comment = '%1 = canal, %2 = cód. reserva, %3 = alojamiento';
        VatDescLbl: Label 'IVA comisión %1 %2', Comment = '%1 = canal, %2 = cód. reserva';
        Desc: Text;
    begin
        if DocType = DocType::"Credit Memo" then
            Sign := -1
        else
            Sign := 1;

        // La aplicación al documento solo es posible cuando este se ha registrado;
        // en modo manual el usuario aplica al registrar el diario.
        if AutoPost then begin
            CustLedgEntry.SetRange("Customer No.", Setup."Generic Customer No.");
            if DocType = DocType::"Credit Memo" then
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo")
            else
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            CustLedgEntry.SetRange("Document No.", Buffer."Posted Document No.");
            CustLedgEntry.FindFirst();
        end;

        Desc := StrSubstNo(FeeDescLbl, Buffer.Channel, Buffer."Reservation Code", Buffer.Listing);

        // 1ª pata: movimiento del cliente aplicado al documento de la reserva.
        GenJnlLine.Init();
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := GetDocumentNo(Buffer);
        GenJnlLine.Validate("Posting Date", Buffer."Transaction Date");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Account No.", Setup."Generic Customer No.");
        ClearPaymentMethodBalancing(GenJnlLine);
        GenJnlLine.Validate(Amount, -FeeAmount * Sign);
        if AutoPost then begin
            GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
            GenJnlLine."Applies-to Doc. No." := Buffer."Posted Document No.";
        end;
        GenJnlLine."External Document No." := GetDocumentNo(Buffer);
        GenJnlLine.Description := CopyStr(Desc, 1, MaxStrLen(GenJnlLine.Description));
        ApplyJournalDimensions(GenJnlLine, Buffer);
        EmitJournalLine(GenJnlLine, GenJnlPostLine);

        // Contrapartida por el mismo importe, en el mismo documento.
        case Setup."Commission Treatment" of
            Setup."Commission Treatment"::Vendor:
                // Cargo (o abono) al proveedor del canal por todo lo retenido.
                PostCommissionLeg(GenJnlLine, GenJnlPostLine, Buffer,
                    GenJnlLine."Account Type"::Vendor, Setup.GetVendorNo(Buffer.Channel), FeeAmount * Sign, Desc);
            Setup."Commission Treatment"::"G/L Account":
                begin
                    // Comisiones a la cuenta de gasto; el IVA retenido (Booking) a su
                    // cuenta propia, o a la de comisiones si no está configurada.
                    VatFee := Abs(Buffer."VAT Fee Amount");
                    if (VatFee <> 0) and (Setup."Fee VAT G/L Account" <> '') then begin
                        PostCommissionLeg(GenJnlLine, GenJnlPostLine, Buffer,
                            GenJnlLine."Account Type"::"G/L Account", Setup."Commission G/L Account", (FeeAmount - VatFee) * Sign, Desc);
                        PostCommissionLeg(GenJnlLine, GenJnlPostLine, Buffer,
                            GenJnlLine."Account Type"::"G/L Account", Setup."Fee VAT G/L Account", VatFee * Sign,
                            StrSubstNo(VatDescLbl, Buffer.Channel, Buffer."Reservation Code"));
                    end else
                        PostCommissionLeg(GenJnlLine, GenJnlPostLine, Buffer,
                            GenJnlLine."Account Type"::"G/L Account", Setup."Commission G/L Account", FeeAmount * Sign, Desc);
                end;
        end;
    end;

    local procedure PostCommissionLeg(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Buffer: Record "BeDyn Portal Import Buffer"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LegAmount: Decimal; Desc: Text)
    begin
        if LegAmount = 0 then
            exit;
        GenJnlLine.Init();
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := GetDocumentNo(Buffer);
        GenJnlLine.Validate("Posting Date", Buffer."Transaction Date");
        GenJnlLine.Validate("Account Type", AccountType);
        GenJnlLine.Validate("Account No.", AccountNo);
        if AccountType = GenJnlLine."Account Type"::"G/L Account" then
            ClearAccountVatConfig(GenJnlLine);
        ClearPaymentMethodBalancing(GenJnlLine);
        GenJnlLine.Validate(Amount, LegAmount);
        GenJnlLine."External Document No." := GetDocumentNo(Buffer);
        GenJnlLine.Description := CopyStr(Desc, 1, MaxStrLen(GenJnlLine.Description));
        ApplyJournalDimensions(GenJnlLine, Buffer);
        EmitJournalLine(GenJnlLine, GenJnlPostLine);
    end;

    // Registra la línea directamente (registro automático) o la deja en el diario y
    // sección de pagos configurados para que el usuario la registre.
    local procedure EmitJournalLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        if AutoPost then begin
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            exit;
        end;
        GenJnlLine."Journal Template Name" := Setup."Payment Journal Template";
        GenJnlLine."Journal Batch Name" := Setup."Payment Journal Batch";
        GenJnlLine."Line No." := NextJournalLineNo();
        GenJnlLine.Insert(true);
    end;

    local procedure NextJournalLineNo(): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", Setup."Payment Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", Setup."Payment Journal Batch");
        if GenJnlLine.FindLast() then
            exit(GenJnlLine."Line No." + 10000);
        exit(10000);
    end;

    // ============================ PAYOUTS ============================

    local procedure ProcessPayout(var Buffer: Record "BeDyn Portal Import Buffer"): Boolean
    var
        JnlErr: Label 'Error al registrar el payout: %1', Comment = '%1 = error';
        PayoutSkipLbl: Label 'Payout: omitido (activar "Contabilizar payouts" en la configuración para contabilizarlo).';
        DocNo: Code[20];
    begin
        // Salvaguarda por si la línea se validó antes de desactivar los payouts.
        if not Setup."Process Payouts" then begin
            Buffer.SetSkippedState(PayoutSkipLbl);
            exit(true);
        end;

        DocNo := CopyStr(GetChannelPrefix(Buffer.Channel) + Format(Buffer."Entry No."), 1, 20);
        Commit();
        if not TryPostPayoutJournal(Buffer, DocNo) then begin
            Buffer.SetErrorState(StrSubstNo(JnlErr, GetLastErrorText()));
            exit(false);
        end;
        Buffer.Status := Buffer.Status::Posted;
        Buffer."Posted Document No." := DocNo;
        Buffer."Error Message" := '';
        Buffer.Modify(true);
        exit(true);
    end;

    // Cobro del payout: cargo al banco del canal y abono al cliente genérico como
    // pago a cuenta, sin aplicar (la aplicación contra las facturas pendientes se
    // hace a mano).
    [TryFunction]
    local procedure TryPostPayoutJournal(var Buffer: Record "BeDyn Portal Import Buffer"; DocNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PayoutDescLbl: Label 'Payout %1 %2', Comment = '%1 = canal, %2 = fecha';
        BankAccountNo: Code[20];
    begin
        BankAccountNo := Setup.GetPayoutBankAccount(Buffer.Channel);

        GenJnlLine.Init();
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := DocNo;
        GenJnlLine.Validate("Posting Date", Buffer."Transaction Date");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
        GenJnlLine.Validate("Account No.", BankAccountNo);
        GenJnlLine.Validate(Amount, Buffer."Paid Out Amount");
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::Customer);
        GenJnlLine.Validate("Bal. Account No.", Setup."Generic Customer No.");
        GenJnlLine."Payment Method Code" := '';
        GenJnlLine."External Document No." := CopyStr(GetPayoutReference(Buffer), 1, MaxStrLen(GenJnlLine."External Document No."));
        GenJnlLine.Description := CopyStr(StrSubstNo(PayoutDescLbl, Buffer.Channel, Buffer."Transaction Date"), 1, MaxStrLen(GenJnlLine.Description));
        ApplyJournalDimensions(GenJnlLine, Buffer);
        EmitJournalLine(GenJnlLine, GenJnlPostLine);
    end;

    local procedure GetChannelPrefix(Channel: Enum "BeDyn Portal Channel"): Text[2]
    begin
        case Channel of
            Channel::Airbnb:
                exit('AB');
            Channel::Booking:
                exit('BK');
        end;
        exit('PT');
    end;

    local procedure GetPayoutReference(var Buffer: Record "BeDyn Portal Import Buffer"): Text
    begin
        if Buffer."Reference Code" <> '' then
            exit(Buffer."Reference Code");
        exit(Buffer."Payout Group ID");
    end;

    // Validar el nº de cuenta de un cliente/proveedor arrastra su forma de pago a la
    // línea de diario y, si esa forma de pago tiene cuenta de contrapartida (cuenta
    // puente tipo 555…), BC la pone como contrapartida de la línea: cada pata se
    // liquidaría sola contra la cuenta puente en vez de formar el asiento
    // cliente-proveedor. Se limpia para que las patas se compensen entre sí.
    local procedure ClearPaymentMethodBalancing(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Payment Method Code" := '';
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine."Bal. Account No." := '';
    end;

    // Sin IVA en el diario de comisión: se limpia la configuración de registro que
    // arrastra la cuenta contable.
    local procedure ClearAccountVatConfig(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
        GenJnlLine."Gen. Bus. Posting Group" := '';
        GenJnlLine."Gen. Prod. Posting Group" := '';
        GenJnlLine."VAT Bus. Posting Group" := '';
        GenJnlLine."VAT Prod. Posting Group" := '';
        GenJnlLine."VAT %" := 0;
        GenJnlLine."VAT Amount" := 0;
    end;

    // ============================ DIMENSIONES ============================

    // Crea el valor de dimensión de la propiedad si no existe (según configuración).
    local procedure EnsureDimensionValue(var Buffer: Record "BeDyn Portal Import Buffer")
    var
        DimValue: Record "Dimension Value";
        MissingDimErr: Label 'El valor %1 no existe en la dimensión %2 y la creación automática está desactivada.', Comment = '%1 = código propiedad, %2 = dimensión';
    begin
        if (Setup."Property Dimension Code" = '') or (Buffer."Property Code" = '') then
            exit;
        if DimValue.Get(Setup."Property Dimension Code", Buffer."Property Code") then
            exit;
        if not Setup."Auto Create Dim. Values" then
            Error(MissingDimErr, Buffer."Property Code", Setup."Property Dimension Code");
        DimValue.Init();
        DimValue."Dimension Code" := Setup."Property Dimension Code";
        DimValue.Code := Buffer."Property Code";
        DimValue.Name := CopyStr(GetPropertyName(Buffer), 1, MaxStrLen(DimValue.Name));
        DimValue.Insert(true);
    end;

    local procedure GetPropertyName(var Buffer: Record "BeDyn Portal Import Buffer"): Text
    var
        Mapping: Record "BeDyn Portal Listing Mapping";
    begin
        if Mapping.GetByChannel(Buffer.Channel, Buffer.GetListingKey()) and (Mapping."Property Name" <> '') then
            exit(Mapping."Property Name");
        exit(Buffer.Listing);
    end;

    // Dimensiones de propiedad y canal para la cabecera de la factura de venta
    // (las líneas y los movimientos generados las heredan).
    local procedure ApplyHeaderDimensions(var SalesHeader: Record "Sales Header"; var Buffer: Record "BeDyn Portal Import Buffer")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        SalesHeader."Dimension Set ID" := BuildDimensionSet(SalesHeader."Dimension Set ID", Buffer);
        DimMgt.UpdateGlobalDimFromDimSetID(
            SalesHeader."Dimension Set ID",
            SalesHeader."Shortcut Dimension 1 Code",
            SalesHeader."Shortcut Dimension 2 Code");
    end;

    // Dimensiones de propiedad y canal para las líneas de diario.
    local procedure ApplyJournalDimensions(var GenJnlLine: Record "Gen. Journal Line"; var Buffer: Record "BeDyn Portal Import Buffer")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        GenJnlLine."Dimension Set ID" := BuildDimensionSet(GenJnlLine."Dimension Set ID", Buffer);
        DimMgt.UpdateGlobalDimFromDimSetID(
            GenJnlLine."Dimension Set ID",
            GenJnlLine."Shortcut Dimension 1 Code",
            GenJnlLine."Shortcut Dimension 2 Code");
    end;

    local procedure BuildDimensionSet(DimSetID: Integer; var Buffer: Record "BeDyn Portal Import Buffer"): Integer
    begin
        if (Setup."Property Dimension Code" <> '') and (Buffer."Property Code" <> '') then
            DimSetID := AddDimensionToSet(DimSetID, Setup."Property Dimension Code", Buffer."Property Code");
        if (Setup."Channel Dimension Code" <> '') and (Setup.GetChannelDimValue(Buffer.Channel) <> '') then
            DimSetID := AddDimensionToSet(DimSetID, Setup."Channel Dimension Code", Setup.GetChannelDimValue(Buffer.Channel));
        exit(DimSetID);
    end;

    local procedure AddDimensionToSet(DimSetID: Integer; DimCode: Code[20]; DimValueCode: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimValue: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
    begin
        DimValue.Get(DimCode, DimValueCode);
        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        TempDimSetEntry.SetRange("Dimension Code", DimCode);
        if TempDimSetEntry.FindFirst() then
            TempDimSetEntry.Delete();
        TempDimSetEntry.Reset();
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Set ID" := 0;
        TempDimSetEntry."Dimension Code" := DimCode;
        TempDimSetEntry."Dimension Value Code" := DimValueCode;
        TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
        TempDimSetEntry.Insert();
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;
}
