namespace BeDynamic.ReservationImport;

using BeDynamic.PropertyWizard;
using System.Environment;

codeunit 82803 "BeDyn Res. Import Router"
{
    // Reparte las líneas del fichero entre las empresas de Business Central.
    //
    // El segundo segmento del código de propiedad (ES-[01]-01-065) dice de qué
    // gestora es la reserva, y cada gestora apunta a una empresa. Las líneas que
    // no son de la empresa actual se copian con ChangeCompany a la hoja de
    // importación de la suya y se borran de aquí; después, en cada empresa, se
    // validan y se procesan por su cuenta.
    //
    // El ChangeCompany se hace sobre la hoja de importación a propósito, no sobre
    // la reserva. Crear la reserva directamente en la otra empresa no funcionaría:
    // los desencadenadores de tabla se ejecutan siempre en el contexto de la
    // empresa actual, así que el nº de reserva saldría de la serie numérica de
    // esta empresa, y el Id de conjunto de dimensiones apuntaría a un conjunto de
    // esta empresa, que en la otra significa algo distinto o no existe. Moviendo
    // el staging, cada empresa crea lo suyo de forma nativa y correcta.

    procedure DistributeBatch(BatchCode: Code[20])
    var
        ImportLine: Record "BeDyn Res. Import Line";
        EntriesToMove: List of [Integer];
        SentPerCompany: Dictionary of [Text, Integer];
        EntryNo: Integer;
        Kept: Integer;
        Sent: Integer;
        Blocked: Integer;
        DoneMsg: Label 'Se quedan en %1: %2 líneas. Enviadas a otras empresas: %3.%4', Comment = '%1 = empresa actual, %2 = líneas propias, %3 = enviadas, %4 = detalle por empresa';
        BlockedMsg: Label '\\Sin empresa destino (revisa el mensaje de la línea): %1.', Comment = '%1 = líneas sin destino';
    begin
        ImportLine.SetRange("Batch Code", BatchCode);
        ImportLine.SetFilter(Status, '<>%1', ImportLine.Status::Processed);
        if ImportLine.FindSet() then
            repeat
                ResolveTargetCompany(ImportLine);
                ImportLine.Modify(true);
                case true of
                    ImportLine."Target Company" = '':
                        Blocked += 1;
                    ImportLine."Target Company" = CompanyName():
                        Kept += 1;
                    else
                        EntriesToMove.Add(ImportLine."Entry No.");
                end;
            until ImportLine.Next() = 0;

        // El movimiento va en una segunda pasada: no conviene ir borrando el
        // registro sobre el que se está iterando.
        foreach EntryNo in EntriesToMove do
            if ImportLine.Get(EntryNo) then
                if MoveLine(ImportLine) then begin
                    CountForCompany(SentPerCompany, ImportLine."Target Company");
                    ImportLine.Delete(true);
                    Sent += 1;
                end else
                    ImportLine.Modify(true);

        if Blocked = 0 then
            Message(DoneMsg, CompanyName(), Kept, Sent, DescribeCompanies(SentPerCompany))
        else
            Message(DoneMsg + BlockedMsg, CompanyName(), Kept, Sent, DescribeCompanies(SentPerCompany), Blocked);
    end;

    local procedure ResolveTargetCompany(var ImportLine: Record "BeDyn Res. Import Line")
    var
        MgtCompany: Record "BeDyn Property Mgt. Company";
        TargetCompany: Record Company;
        NoMgtCompanyErr: Label 'El código de propiedad %1 no lleva un segundo segmento que corresponda a ninguna empresa gestora.', Comment = '%1 = código de propiedad';
        NoCompanyErr: Label 'La empresa gestora %1 (%2) no tiene empresa de Business Central asignada.', Comment = '%1 = código de gestora, %2 = nombre de gestora';
        UnknownCompanyErr: Label 'La empresa %1, asignada a la gestora %2, no existe en esta base de datos.', Comment = '%1 = empresa, %2 = código de gestora';
    begin
        ImportLine."Mgt. Company Code" := '';
        ImportLine."Target Company" := '';

        if not MgtCompany.GetFromPropertyCode(ImportLine."Property Code CSV") then begin
            ImportLine.SetError(StrSubstNo(NoMgtCompanyErr, ImportLine."Property Code CSV"));
            exit;
        end;
        ImportLine."Mgt. Company Code" := MgtCompany.Code;

        if MgtCompany."Company Name" = '' then begin
            ImportLine.SetError(StrSubstNo(NoCompanyErr, MgtCompany.Code, MgtCompany.Name));
            exit;
        end;
        if not TargetCompany.Get(MgtCompany."Company Name") then begin
            ImportLine.SetError(StrSubstNo(UnknownCompanyErr, MgtCompany."Company Name", MgtCompany.Code));
            exit;
        end;

        ImportLine."Target Company" := MgtCompany."Company Name";
    end;

    // Copia la línea a la hoja de importación de su empresa. Devuelve false si ya
    // estaba allí, para que reenviar el mismo lote no la duplique.
    local procedure MoveLine(var SourceLine: Record "BeDyn Res. Import Line"): Boolean
    var
        TargetLine: Record "BeDyn Res. Import Line";
        AlreadySentErr: Label 'La reserva ya está en la hoja de importación de %1 con este mismo lote.', Comment = '%1 = empresa destino';
    begin
        TargetLine.ChangeCompany(SourceLine."Target Company");
        TargetLine.SetRange("Batch Code", SourceLine."Batch Code");
        TargetLine.SetRange("External Id", SourceLine."External Id");
        if not TargetLine.IsEmpty() then begin
            SourceLine.SetError(StrSubstNo(AlreadySentErr, SourceLine."Target Company"));
            exit(false);
        end;

        TargetLine.Reset();
        TargetLine.Init();
        TargetLine.TransferFields(SourceLine, true);
        // La numeración de la hoja es propia de cada empresa.
        TargetLine."Entry No." := 0;
        // Llega sin validar: los maestros contra los que se comprueba son los de
        // su empresa, no los de esta.
        TargetLine.Status := TargetLine.Status::Pending;
        TargetLine."Error Message" := '';
        TargetLine."Warning Message" := '';
        TargetLine."Property No." := '';
        TargetLine."Room No." := '';
        TargetLine."Tenant No." := '';
        TargetLine."Reservation No." := '';
        TargetLine."Deposit No." := '';
        TargetLine."New Tenant" := false;
        TargetLine."Existing Reservation" := false;
        TargetLine.Insert(true);
        exit(true);
    end;

    local procedure CountForCompany(var SentPerCompany: Dictionary of [Text, Integer]; TargetCompany: Text)
    var
        Current: Integer;
    begin
        if SentPerCompany.ContainsKey(TargetCompany) then
            Current := SentPerCompany.Get(TargetCompany);
        SentPerCompany.Set(TargetCompany, Current + 1);
    end;

    local procedure DescribeCompanies(SentPerCompany: Dictionary of [Text, Integer]) Result: Text
    var
        TargetCompany: Text;
        DetailLbl: Label '\%1: %2 líneas.', Comment = '%1 = empresa, %2 = nº de líneas';
    begin
        foreach TargetCompany in SentPerCompany.Keys() do
            Result += StrSubstNo(DetailLbl, TargetCompany, SentPerCompany.Get(TargetCompany));
    end;
}
