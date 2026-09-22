namespace BeDynamic.PleoImport;

using BeDynamic.PropertyWizard;
using System.Environment;

codeunit 82103 "BeDyn Pleo Import Router"
{
    // Reparte las líneas del lote entre las empresas de Business Central.
    //
    // El segundo segmento del código de propiedad (ES-[01]-01-065) dice de qué
    // gestora es el gasto, y cada gestora apunta a una empresa (Empresas gestoras
    // de propiedades). Las líneas que no son de la empresa actual se copian con
    // ChangeCompany a la hoja de importación de Pleo de la suya y se borran de
    // aquí; después, en cada empresa, se validan y se procesan por su cuenta
    // contra su configuración y sus mapeos.
    //
    // Las líneas sin propiedad (recargas y cashbacks del monedero, gastos sin
    // proyecto) van siempre a la empresa marcada como principal, titular del
    // monedero Pleo, se importen donde se importen.
    //
    // Se mueve el staging y no el documento por la misma razón que en reservas:
    // los desencadenadores de tabla corren en la empresa actual, así que series
    // numéricas, dimensiones y activos fijos deben crearse de forma nativa en la
    // empresa destino.

    procedure DistributeBatch(BatchCode: Code[20])
    var
        Buffer: Record "BeDyn Pleo Import Buffer";
        EntriesToMove: List of [Integer];
        SentPerCompany: Dictionary of [Text, Integer];
        EntryNo: Integer;
        Kept: Integer;
        Sent: Integer;
        Duplicates: Integer;
        Blocked: Integer;
        ErrText: Text;
        ResultText: Text;
        DoneMsg: Label 'Se quedan en %1: %2 líneas. Enviadas a otras empresas: %3.%4', Comment = '%1 = empresa actual, %2 = líneas propias, %3 = enviadas, %4 = detalle por empresa';
        DuplicatesMsg: Label '\Descartadas por estar ya en la empresa destino: %1.', Comment = '%1 = duplicadas';
        BlockedMsg: Label '\Sin empresa destino (revisa el mensaje de la línea): %1.', Comment = '%1 = líneas sin destino';
    begin
        // Solo líneas sin documento generado: las creadas, registradas o pagadas
        // ya son de esta empresa y no se tocan.
        Buffer.SetRange("Batch Code", BatchCode);
        Buffer.SetFilter(Status, '%1|%2|%3|%4', Buffer.Status::Pending, Buffer.Status::Validated, Buffer.Status::Error, Buffer.Status::Skipped);
        if Buffer.FindSet() then
            repeat
                ErrText := ResolveTargetCompany(Buffer);
                if ErrText <> '' then
                    Buffer.SetErrorState(ErrText)
                else
                    Buffer.Modify(true);
                case true of
                    Buffer."Target Company" = '':
                        Blocked += 1;
                    UpperCase(Buffer."Target Company") = UpperCase(CompanyName()):
                        Kept += 1;
                    else
                        EntriesToMove.Add(Buffer."Entry No.");
                end;
            until Buffer.Next() = 0;

        // El movimiento va en una segunda pasada: no conviene ir borrando el
        // registro sobre el que se está iterando.
        foreach EntryNo in EntriesToMove do
            if Buffer.Get(EntryNo) then begin
                if MoveLine(Buffer) then begin
                    CountForCompany(SentPerCompany, Buffer."Target Company");
                    Sent += 1;
                end else
                    Duplicates += 1;
                Buffer.Delete(true);
            end;

        ResultText := StrSubstNo(DoneMsg, CompanyName(), Kept, Sent, DescribeCompanies(SentPerCompany));
        if Duplicates > 0 then
            ResultText += StrSubstNo(DuplicatesMsg, Duplicates);
        if Blocked > 0 then
            ResultText += StrSubstNo(BlockedMsg, Blocked);
        Message(ResultText);
    end;

    // Deja en la línea la gestora y la empresa destino. Devuelve el motivo si no
    // se puede determinar la empresa (la línea se queda aquí en error).
    local procedure ResolveTargetCompany(var Buffer: Record "BeDyn Pleo Import Buffer"): Text
    var
        MgtCompany: Record "BeDyn Property Mgt. Company";
        TargetCompany: Record Company;
        NoMainCompanyErr: Label 'La línea no tiene propiedad y no hay ninguna empresa gestora marcada como principal (Empresas gestoras de propiedades).';
        NoMgtCompanyErr: Label 'El código de propiedad %1 no lleva un segundo segmento que corresponda a ninguna empresa gestora.', Comment = '%1 = código de propiedad';
        NoCompanyErr: Label 'La empresa gestora %1 (%2) no tiene empresa de Business Central asignada.', Comment = '%1 = código de gestora, %2 = nombre de gestora';
        UnknownCompanyErr: Label 'La empresa %1, asignada a la gestora %2, no existe en esta base de datos.', Comment = '%1 = empresa, %2 = código de gestora';
    begin
        Buffer."Mgt. Company Code" := '';
        Buffer."Target Company" := '';

        if Buffer."Project Code" = '' then begin
            // Sin propiedad: recargas, cashbacks y gastos sin proyecto van a la
            // empresa principal, titular del monedero.
            if not MgtCompany.GetMainCompany() then
                exit(NoMainCompanyErr);
        end else
            if not MgtCompany.GetFromPropertyCode(Buffer."Project Code") then
                exit(StrSubstNo(NoMgtCompanyErr, Buffer."Project Code"));

        Buffer."Mgt. Company Code" := MgtCompany.Code;
        if MgtCompany."Company Name" = '' then
            exit(StrSubstNo(NoCompanyErr, MgtCompany.Code, MgtCompany.Name));
        if not TargetCompany.Get(MgtCompany."Company Name") then
            exit(StrSubstNo(UnknownCompanyErr, MgtCompany."Company Name", MgtCompany.Code));

        Buffer."Target Company" := MgtCompany."Company Name";
        exit('');
    end;

    // Copia la línea a la hoja de importación de Pleo de su empresa. Devuelve
    // false si ese gasto (Expense ID) ya está allí, en la hoja o en el archivo:
    // entonces la línea sobra y el llamador la descarta como duplicada.
    local procedure MoveLine(var SourceBuffer: Record "BeDyn Pleo Import Buffer"): Boolean
    var
        TargetBuffer: Record "BeDyn Pleo Import Buffer";
        TargetArchive: Record "BeDyn Pleo Expense Archive";
    begin
        TargetBuffer.ChangeCompany(SourceBuffer."Target Company");
        TargetArchive.ChangeCompany(SourceBuffer."Target Company");
        if SourceBuffer."Expense ID" <> '' then begin
            TargetBuffer.SetCurrentKey("Expense ID");
            TargetBuffer.SetRange("Expense ID", SourceBuffer."Expense ID");
            if not TargetBuffer.IsEmpty() then
                exit(false);
            TargetArchive.SetCurrentKey("Expense ID");
            TargetArchive.SetRange("Expense ID", SourceBuffer."Expense ID");
            if not TargetArchive.IsEmpty() then
                exit(false);
        end;

        TargetBuffer.Reset();
        TargetBuffer.Init();
        TargetBuffer.TransferFields(SourceBuffer, true);
        // La numeración de la hoja es propia de cada empresa.
        TargetBuffer."Entry No." := 0;
        // Llega sin validar: proveedor, cuenta, activo, comprador y proyecto se
        // resuelven contra los maestros y mapeos de su empresa.
        TargetBuffer.Status := TargetBuffer.Status::Pending;
        TargetBuffer."Error Message" := '';
        TargetBuffer."Warning Message" := '';
        TargetBuffer."Mapped Vendor No." := '';
        TargetBuffer."G/L Account No." := '';
        TargetBuffer.CAPEX := false;
        TargetBuffer."Fixed Asset No." := '';
        TargetBuffer."Purchaser Code" := '';
        TargetBuffer.Extraordinary := false;
        TargetBuffer."Job No." := '';
        TargetBuffer."Job Task No." := '';
        TargetBuffer."Source Company" := CopyStr(CompanyName(), 1, MaxStrLen(TargetBuffer."Source Company"));
        TargetBuffer.Insert(true);
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
