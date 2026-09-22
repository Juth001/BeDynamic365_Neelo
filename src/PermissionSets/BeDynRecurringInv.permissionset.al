namespace Neelo.RecurringInvoicing;

using BeDynamic.PropertyManagement;
using Neelo.RecurringInvoicing;

permissionset 81000 "BeDyn Recurring Inv."
{
    Assignable = true;
    Permissions = tabledata "BeDyn Billing Code" = RIMD,
        tabledata "BeDyn Customer Billing" = RIMD,
        tabledata "BeDyn Deposit" = RIM,
        tabledata "BeDyn Invoice Import Archive" = RIMD,
        tabledata "BeDyn Invoice Import Buffer" = RIMD,
        tabledata "BeDyn Recurring Inv. Setup" = RIMD,
        tabledata "BeDyn Reservation" = RIM,
        table "BeDyn Billing Code" = X,
        table "BeDyn Customer Billing" = X,
        table "BeDyn Invoice Import Archive" = X,
        table "BeDyn Invoice Import Buffer" = X,
        table "BeDyn Recurring Inv. Setup" = X,
        codeunit "BeDyn Cartera Subscribers" = X,
        codeunit "BeDyn Import Mgt." = X,
        codeunit "BeDyn Posting Mgt." = X,
        codeunit "BeDyn Posting Subscribers" = X,
        codeunit "BeDyn Remittance Context" = X,
        codeunit "BeDyn Remittance Subscribers" = X,
        codeunit "BeDyn Validation Mgt." = X,
        codeunit "BeDyn Validation Tests" = X,
        page "BeDyn Billing Codes" = X,
        page "BeDyn Customer Billing" = X,
        page "BeDyn Invoice Import Archive" = X,
        page "BeDyn Invoice Import Buffer" = X,
        page "BeDyn Recurring Inv. Setup" = X;
}