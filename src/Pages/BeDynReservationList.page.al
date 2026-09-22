namespace BeDynamic.PropertyManagement;

page 82511 "BeDyn Reservation List"
{
    PageType = List;
    SourceTable = "BeDyn Reservation";
    Caption = 'Reservas';
    CardPageId = "BeDyn Reservation Card";
    Editable = false;
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de la reserva.';
                }
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad reservada.';
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Subpropiedad reservada (solo propiedades alquiladas por subpropiedades).';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Contrato de la propiedad al que se vincula la reserva.';
                }
                field("Tenant No."; Rec."Tenant No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Inquilino de la reserva.';
                }
                field("Tenant Name"; Rec."Tenant Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del inquilino.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha de inicio de la reserva.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha de fin de la reserva.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado de la reserva.';
                }
                field("Rental Amount"; Rec."Rental Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Importe del alquiler.';
                }
                field("Services Amount"; Rec."Services Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Importe de los servicios adicionales.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(AvailabilityCalendar)
            {
                ApplicationArea = All;
                Caption = 'Calendario disponibilidad';
                Image = Calendar;
                ToolTip = 'Ver la disponibilidad de las subpropiedades de la propiedad de la reserva en un calendario mensual.';

                trigger OnAction()
                begin
                    ShowAvailabilityCalendar();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(AvailabilityCalendar_Promoted; AvailabilityCalendar)
                {
                }
            }
        }
    }

    local procedure ShowAvailabilityCalendar()
    var
        PropertyRoom: Record "BeDyn Property Room";
        CalendarPage: Page "BeDyn Room Avail. Calendar";
    begin
        Rec.TestField("Property No.");
        PropertyRoom.SetRange("Property No.", Rec."Property No.");
        CalendarPage.SetTableView(PropertyRoom);
        CalendarPage.SetInitialDate(Rec."Start Date");
        CalendarPage.Run();
    end;
}
