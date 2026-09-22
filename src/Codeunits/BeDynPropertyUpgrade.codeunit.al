namespace BeDynamic.PropertyManagement;

using System.Upgrade;

codeunit 82508 "BeDyn Property Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        EnableLinkedPropertyCodes();
    end;

    // La numeración enlazada nace activada. El InitValue del campo solo cubre las
    // bases donde la configuración todavía no existe, así que en las que ya la
    // tenían creada hay que marcarla al actualizar.
    local procedure EnableLinkedPropertyCodes()
    var
        MgtSetup: Record "BeDyn Property Mgt. Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(LinkPropertyCodesTag()) then
            exit;
        if MgtSetup.Get() then begin
            MgtSetup."Link Property Codes" := true;
            MgtSetup.Modify();
        end;
        UpgradeTag.SetUpgradeTag(LinkPropertyCodesTag());
    end;

    local procedure LinkPropertyCodesTag(): Code[250]
    begin
        exit('BeDynamic-NEE-LinkPropertyCodes-20260804');
    end;
}
