namespace BeDynamic.ReservationImport;

using BeDynamic.PropertyManagement;
using BeDynamic.PropertyWizard;
using Microsoft.Finance.Dimension;
using System.Environment;

permissionset 82800 "BeDyn Res. Import"
{
    Assignable = true;
    Caption = 'Importación de reservas';

    Permissions =
        table "BeDyn Res. Import Line" = X,
        tabledata "BeDyn Res. Import Line" = RIMD,
        tabledata "BeDyn Customer Type" = RIMD,
        tabledata "BeDyn Guest Type" = RIMD,
        tabledata "BeDyn Property Mgt. Setup" = R,
        tabledata "BeDyn Property Setup" = R,
        tabledata "BeDyn Property" = R,
        tabledata "BeDyn Property Room" = R,
        tabledata "BeDyn Tenant" = RIM,
        tabledata "BeDyn Reservation" = RIM,
        tabledata "BeDyn Deposit" = RIM,
        tabledata "Dimension Value" = R,
        tabledata "Default Dimension" = R,
        tabledata "BeDyn Property Mgt. Company" = R,
        tabledata Company = R,
        codeunit "BeDyn Res. CSV Reader" = X,
        codeunit "BeDyn Res. Import Router" = X,
        codeunit "BeDyn Deposit Posting" = X,
        codeunit "BeDyn Res. Import Validation" = X,
        codeunit "BeDyn Res. Import Process" = X,
        page "BeDyn Res. Import Wksh." = X,
        page "BeDyn Customer Types" = X,
        page "BeDyn Guest Types" = X;
}
