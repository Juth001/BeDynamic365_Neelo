namespace BeDynamic.PropertyManagement;

page 82537 "BeDyn Property Activities"
{
    Caption = 'Actividades de propiedades';
    PageType = CardPart;
    SourceTable = "BeDyn Property Cue";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            cuegroup(Portfolio)
            {
                Caption = 'Cartera';

                field(Properties; Rec.Properties)
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Property List";
                    ToolTip = 'Número total de propiedades registradas.';
                }
                field("Active Contracts"; Rec."Active Contracts")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Property Contract List";
                    ToolTip = 'Contratos de propiedad en estado activo.';
                }
                field("Draft Contracts"; Rec."Draft Contracts")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Property Contract List";
                    ToolTip = 'Contratos de propiedad en estado borrador.';
                }
                field("Contracts Expiring"; Rec."Contracts Expiring")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Property Contract List";
                    ToolTip = 'Contratos activos cuya fecha fin cae en los próximos 30 días.';
                }
            }
            cuegroup(Reservations)
            {
                Caption = 'Reservas';

                field("Pending Reservations"; Rec."Pending Reservations")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Reservation List";
                    ToolTip = 'Reservas pendientes de confirmar.';
                }
                field("Confirmed Reservations"; Rec."Confirmed Reservations")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Reservation List";
                    ToolTip = 'Reservas confirmadas a la espera de check-in.';
                }
                field("Arrivals Today"; Rec."Arrivals Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Reservation List";
                    ToolTip = 'Reservas cuya fecha de inicio es hoy.';
                }
                field("Departures Today"; Rec."Departures Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Reservation List";
                    ToolTip = 'Reservas con check-in hecho cuya fecha fin es hoy.';
                }
                field("Guests Checked In"; Rec."Guests Checked In")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Reservation List";
                    ToolTip = 'Reservas con inquilinos actualmente alojados.';
                }
            }
            cuegroup(Deposits)
            {
                Caption = 'Fianzas';

                field("Pending Deposits"; Rec."Pending Deposits")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Deposit List";
                    ToolTip = 'Fianzas pendientes de cobro.';
                }
                field("Deposits Collected"; Rec."Deposits Collected")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BeDyn Deposit List";
                    ToolTip = 'Fianzas cobradas pendientes de devolución o retención.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        Rec.SetRange("Today Filter", WorkDate());
        Rec.SetRange("Date Filter", WorkDate(), CalcDate('<+30D>', WorkDate()));
    end;
}
