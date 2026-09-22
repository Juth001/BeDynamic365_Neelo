namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using BeDynamic.PropertyWizard;

permissionset 82700 "BeDyn Cleaning Imp."
{
    Caption = 'Importación limpiezas';
    Assignable = true;

    Permissions =
        table "BeDyn Cleaning Import Line" = X,
        tabledata "BeDyn Cleaning Import Line" = RIMD,
        table "BeDyn Cleaning Service" = X,
        tabledata "BeDyn Cleaning Service" = RIMD,
        table "BeDyn Cleaning Service Price" = X,
        tabledata "BeDyn Cleaning Service Price" = RIMD,
        tabledata "BeDyn Property Mgt. Setup" = R,
        tabledata "BeDyn Property" = R,
        tabledata "BeDyn Property Task Template" = R,
        codeunit "BeDyn Cleaning CSV Import" = X,
        codeunit "BeDyn Cleaning Validation" = X,
        codeunit "BeDyn Cleaning Reclass Mgt." = X,
        page "BeDyn Cleaning Import Wksh." = X,
        page "BeDyn Cleaning Pending Inv." = X,
        page "BeDyn Cleaning Services" = X,
        page "BeDyn Cleaning Service Prices" = X;
}
