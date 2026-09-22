namespace BeDynamic.PropertyManagement;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.AuditCodes;

codeunit 82509 "BeDyn Deposit Posting"
{
    // Asiento del cobro de una fianza: cargo en la cuenta puente y abono en la
    // cuenta de fianzas, por el importe entregado por el inquilino.
    //
    // El documento es el nº de la reserva y el documento externo su código de
    // origen, de modo que desde la ficha de la fianza se llega a los dos apuntes
    // y desde el asiento se reconoce la reserva.
    //
    // Se registra con Gen. Jnl.-Post Line, sin pasar por una sección de diario:
    // cada fianza es un asiento cuadrado de dos apuntes y no hay nada que revisar
    // en bloque, a diferencia de la reclasificación de limpiezas.

    procedure PostDeposit(var Deposit: Record "BeDyn Deposit"; PostingDate: Date)
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        AlreadyPostedErr: Label 'La fianza %1 ya está registrada con el documento %2.', Comment = '%1 = Nº fianza, %2 = nº de documento';
        NoAmountErr: Label 'La fianza %1 no tiene importe que registrar.', Comment = '%1 = Nº fianza';
    begin
        if Deposit.IsPosted() then
            Error(AlreadyPostedErr, Deposit."No.", Deposit."Posting Document No.");
        if Deposit.Amount <= 0 then
            Error(NoAmountErr, Deposit."No.");

        PropertySetup.GetInstance();
        PropertySetup.TestField("Deposit Bridge Account No.");
        PropertySetup.TestField("Deposit G/L Account No.");

        if PostingDate = 0D then
            PostingDate := WorkDate();

        BuildJournalLine(GenJnlLine, Deposit, PropertySetup, PostingDate);
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        Deposit."Posting Document No." := GenJnlLine."Document No.";
        Deposit."Posting Date" := PostingDate;
        if Deposit."Collection Date" = 0D then
            Deposit."Collection Date" := PostingDate;
        Deposit.Modify(true);
    end;

    // Una sola línea con contrapartida: el motor de registro genera los dos
    // apuntes, cargo en la puente y abono en la de fianzas, con el mismo
    // documento y la misma fecha.
    local procedure BuildJournalLine(var GenJnlLine: Record "Gen. Journal Line"; Deposit: Record "BeDyn Deposit"; PropertySetup: Record "BeDyn Property Mgt. Setup"; PostingDate: Date)
    var
        SourceCodeSetup: Record "Source Code Setup";
        DescriptionLbl: Label 'Fianza %1 - %2', Comment = '%1 = Nº fianza, %2 = nombre del inquilino';
    begin
        GenJnlLine.Init();
        GenJnlLine."Line No." := 10000;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := DocumentNo(Deposit);
        GenJnlLine."External Document No." := ExternalDocumentNo(Deposit);
        GenJnlLine.Validate("Posting Date", PostingDate);

        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", PropertySetup."Deposit Bridge Account No.");
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", PropertySetup."Deposit G/L Account No.");
        // Importe positivo: carga la cuenta del apunte (puente) y abona la
        // contrapartida (fianzas).
        GenJnlLine.Validate(Amount, Deposit.Amount);

        // La fianza no está sujeta a IVA: se limpian los grupos que hayan podido
        // llegar de las cuentas al validarlas.
        ClearVATPosting(GenJnlLine);

        Deposit.CalcFields("Tenant Name");
        GenJnlLine.Description := CopyStr(StrSubstNo(DescriptionLbl, Deposit."No.", Deposit."Tenant Name"), 1, MaxStrLen(GenJnlLine.Description));

        if SourceCodeSetup.Get() then
            GenJnlLine."Source Code" := SourceCodeSetup."General Journal";

        ApplyDimensions(GenJnlLine, Deposit);
    end;

    // Las dimensiones se ponen al final: validar las cuentas las reinicia. Se
    // toman de la reserva, que ya trae la propiedad y el canal.
    local procedure ApplyDimensions(var GenJnlLine: Record "Gen. Journal Line"; Deposit: Record "BeDyn Deposit")
    var
        Reservation: Record "BeDyn Reservation";
        DimMgt: Codeunit DimensionManagement;
    begin
        if Deposit."Reservation No." = '' then
            exit;
        if not Reservation.Get(Deposit."Reservation No.") then
            exit;
        if Reservation."Dimension Set ID" = 0 then
            exit;
        GenJnlLine."Dimension Set ID" := Reservation."Dimension Set ID";
        DimMgt.UpdateGlobalDimFromDimSetID(GenJnlLine."Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code");
    end;

    local procedure ClearVATPosting(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
        GenJnlLine."Gen. Bus. Posting Group" := '';
        GenJnlLine."Gen. Prod. Posting Group" := '';
        GenJnlLine."VAT Bus. Posting Group" := '';
        GenJnlLine."VAT Prod. Posting Group" := '';
        GenJnlLine."Bal. Gen. Posting Type" := GenJnlLine."Bal. Gen. Posting Type"::" ";
        GenJnlLine."Bal. Gen. Bus. Posting Group" := '';
        GenJnlLine."Bal. Gen. Prod. Posting Group" := '';
        GenJnlLine."Bal. VAT Bus. Posting Group" := '';
        GenJnlLine."Bal. VAT Prod. Posting Group" := '';
    end;

    // El documento es el nº de la reserva; si la fianza no cuelga de ninguna, su
    // propio número.
    local procedure DocumentNo(Deposit: Record "BeDyn Deposit"): Code[20]
    begin
        if Deposit."Reservation No." <> '' then
            exit(Deposit."Reservation No.");
        exit(Deposit."No.");
    end;

    local procedure ExternalDocumentNo(Deposit: Record "BeDyn Deposit"): Code[35]
    var
        Reservation: Record "BeDyn Reservation";
    begin
        if Deposit."Reservation No." = '' then
            exit('');
        if not Reservation.Get(Deposit."Reservation No.") then
            exit('');
        exit(Reservation."External Code");
    end;
}
