namespace BeDynamic.PropertyManagement;

report 82501 "BeDyn Gen. Monthly Rent Inv."
{
    Caption = 'Generar facturas de alquiler mensual';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    ApplicationArea = All;

    dataset
    {
        dataitem(Reservation; "BeDyn Reservation")
        {
            DataItemTableView = where("Price Basis" = const("Per Month"), Status = filter(Confirmed | CheckedIn | CheckedOut));
            RequestFilterFields = "Property No.", "Tenant No.", "No.";

            trigger OnPreDataItem()
            begin
                if BillingDate = 0D then
                    BillingDate := WorkDate();
                // Activas en algún momento hasta el fin del mes de facturación y con noches ocupadas.
                SetFilter("Start Date", '<>%1&<=%2', 0D, CalcDate('<CM>', BillingDate));
                SetFilter("End Date", '>%1', 0D);
            end;

            trigger OnAfterGetRecord()
            begin
                if not PropertyBillingMgt.CanInvoiceReservation(Reservation) then begin
                    NoSkipped += 1;
                    exit;
                end;
                if PropertyBillingMgt.CreateMonthlyInvoice(Reservation, BillingDate, BillingDate, false) then
                    NoCreated += 1;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Opciones';

                    field(BillingDateCtrl; BillingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Fecha de facturación';
                        ToolTip = 'Se facturan las mensualidades pendientes hasta el fin del mes de esta fecha. Es también la fecha de registro de las facturas generadas.';
                    }
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        BillingDate := WorkDate();
    end;

    trigger OnPostReport()
    begin
        if not GuiAllowed() then
            exit;
        if NoSkipped > 0 then
            Message(SummaryWithSkippedMsg, NoCreated, NoSkipped)
        else
            Message(SummaryMsg, NoCreated);
    end;

    var
        PropertyBillingMgt: Codeunit "BeDyn Property Billing Mgt.";
        BillingDate: Date;
        NoCreated: Integer;
        NoSkipped: Integer;
        SummaryMsg: Label 'Se han generado %1 facturas.', Comment = '%1 = Nº de facturas creadas';
        SummaryWithSkippedMsg: Label 'Se han generado %1 facturas. Se han omitido %2 reservas porque su inquilino no tiene cliente asociado.', Comment = '%1 = Nº de facturas creadas, %2 = Nº de reservas omitidas';
}
