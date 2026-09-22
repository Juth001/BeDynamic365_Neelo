namespace Neelo.DebtManagement;

// Genera el cuadro de amortización por el sistema francés: cuota constante
// calculada con el capital, el tipo de interés anual, el nº de pagos y los
// pagos por año. El pago adicional por cuota (opcional) amortiza capital extra
// en cada vencimiento y adelanta el final del préstamo, con una última cuota
// menor (como en la plantilla de Excel de referencia). La primera cuota vence
// en la fecha de formalización.
codeunit 81100 "BeDyn Debt Amortization Calc"
{
    procedure GenerateSchedule(var Debt: Record "BeDyn Debt")
    var
        AmortizationLine: Record "BeDyn Debt Amortization Line";
        PeriodRate: Decimal;
        ScheduledPayment: Decimal;
        Balance: Decimal;
        Principal: Decimal;
        Interest: Decimal;
        PaymentNo: Integer;
        MonthsPerPeriod: Integer;
        Months: Integer;
        ReplaceQst: Label 'La deuda %1 ya tiene cuadro de amortización. ¿Sustituirlo?', Comment = '%1 = deuda';
        PaidLinesErr: Label 'La deuda %1 tiene cuotas marcadas como pagadas: no se puede recalcular el cuadro.', Comment = '%1 = deuda';
        FreqErr: Label 'El nº de pagos por año debe ser 1, 2, 3, 4, 6 o 12.';
        DoneMsg: Label 'Cuadro de amortización generado: %1 cuotas de %2 (pago programado).', Comment = '%1 = nº cuotas, %2 = cuota';
    begin
        Debt.TestField(Capital);
        Debt.TestField("No. of Payments");
        Debt.TestField("Start Date");
        if not (Debt."Payments per Year" in [1, 2, 3, 4, 6, 12]) then
            Error(FreqErr);

        // Un cuadro con cuotas ya pagadas no se puede regenerar; uno sin pagar,
        // solo confirmando que se sustituye.
        AmortizationLine.SetRange("Debt No.", Debt."No.");
        AmortizationLine.SetRange(Paid, true);
        if not AmortizationLine.IsEmpty() then
            Error(PaidLinesErr, Debt."No.");
        AmortizationLine.SetRange(Paid);
        if not AmortizationLine.IsEmpty() then begin
            if not Confirm(ReplaceQst, false, Debt."No.") then
                exit;
            AmortizationLine.DeleteAll();
        end;

        MonthsPerPeriod := 12 div Debt."Payments per Year";
        PeriodRate := Debt."Interest Rate %" / 100 / Debt."Payments per Year";
        ScheduledPayment := CalcScheduledPayment(Debt.Capital, PeriodRate, Debt."No. of Payments");

        Balance := Debt.Capital;
        while Balance > 0 do begin
            PaymentNo += 1;
            Interest := Round(Balance * PeriodRate, 0.01);
            Principal := ScheduledPayment + Debt."Additional Payment" - Interest;
            // Última cuota: se amortiza justo el saldo restante, sea por el pago
            // adicional (acaba antes) o por el redondeo en el último pago previsto.
            if (Principal >= Balance) or (PaymentNo >= Debt."No. of Payments") then
                Principal := Balance;

            Months := (PaymentNo - 1) * MonthsPerPeriod;
            AmortizationLine.Init();
            AmortizationLine."Debt No." := Debt."No.";
            AmortizationLine."Line No." := PaymentNo * 10000;
            if Months = 0 then
                AmortizationLine."Amortization Date" := Debt."Start Date"
            else
                AmortizationLine."Amortization Date" := CalcDate(StrSubstNo('<+%1M>', Months), Debt."Start Date");
            AmortizationLine.Validate("Principal Amount", Principal);
            AmortizationLine.Validate("Interest Amount", Interest);
            AmortizationLine.Insert(true);

            Balance -= Principal;
        end;

        Message(DoneMsg, PaymentNo, Format(ScheduledPayment));
    end;

    // Cuota constante del sistema francés: C·i / (1 - (1+i)^-n). Con tipo cero,
    // el capital a partes iguales.
    local procedure CalcScheduledPayment(Capital: Decimal; PeriodRate: Decimal; NoOfPayments: Integer): Decimal
    var
        Factor: Decimal;
    begin
        if PeriodRate = 0 then
            exit(Round(Capital / NoOfPayments, 0.01));
        Factor := Power(1 + PeriodRate, NoOfPayments);
        exit(Round(Capital * PeriodRate * Factor / (Factor - 1), 0.01));
    end;
}
