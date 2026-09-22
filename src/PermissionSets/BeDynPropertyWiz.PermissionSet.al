namespace BeDynamic.PropertyWizard;

using BeDynamic.PropertyManagement;

permissionset 82400 "BeDyn Property Wiz."
{
    Caption = 'Asistente propiedades';
    Assignable = true;

    Permissions =
        table "BeDyn Property Setup" = X,
        tabledata "BeDyn Property Setup" = RIMD,
        table "BeDyn Property Mgt. Company" = X,
        tabledata "BeDyn Property Mgt. Company" = RIMD,
        table "BeDyn Property Task Template" = X,
        tabledata "BeDyn Property Task Template" = RIMD,
        tabledata "BeDyn Property Mgt. Setup" = R,
        tabledata "BeDyn Property Owner" = R,
        tabledata "BeDyn Property" = RI,
        tabledata "BeDyn Property Room" = RIM,
        codeunit "BeDyn Property Creation" = X,
        page "BeDyn Property Setup" = X,
        page "BeDyn Property Mgt. Companies" = X,
        page "BeDyn Property Task Templates" = X,
        page "BeDyn Property Wizard" = X;
}
