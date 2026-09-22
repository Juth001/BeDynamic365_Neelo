namespace BeDynamic.PortalImport;

using BeDynamic.PropertyManagement;

codeunit 82604 "BeDyn Portal Channel Mgt."
{
    // Puente entre el canal de importación (comportamiento del motor: formato CSV y
    // contabilización) y el maestro de Portales del módulo de propiedades: cada canal
    // se corresponde con el portal que tenga ese "Canal de importación".

    /// <summary>Portal asignado al canal; vacío si ninguno lo tiene.</summary>
    procedure FindPortalCode(Channel: Enum "BeDyn Portal Channel"): Code[20]
    var
        Portal: Record "BeDyn Portal";
    begin
        if Channel = Channel::" " then
            exit('');
        Portal.SetRange("Import Channel", Channel);
        if Portal.FindFirst() then
            exit(Portal.Code);
        exit('');
    end;

    /// <summary>Portal del canal; si ninguno lo tiene, lo crea (AIRBNB/BOOKING).</summary>
    procedure EnsurePortal(Channel: Enum "BeDyn Portal Channel"): Code[20]
    var
        Portal: Record "BeDyn Portal";
        PortalCode: Code[20];
    begin
        PortalCode := FindPortalCode(Channel);
        if PortalCode <> '' then
            exit(PortalCode);

        PortalCode := CopyStr(UpperCase(Format(Channel)), 1, MaxStrLen(Portal.Code));
        if PortalCode = '' then
            exit('');
        // Si ya existe un portal con ese código pero sin canal, se le asigna.
        if Portal.Get(PortalCode) then begin
            Portal.Validate("Import Channel", Channel);
            Portal.Modify(true);
            exit(Portal.Code);
        end;
        Portal.Init();
        Portal.Code := PortalCode;
        Portal.Description := Format(Channel);
        Portal.Validate("Import Channel", Channel);
        Portal.Insert(true);
        exit(Portal.Code);
    end;
}
