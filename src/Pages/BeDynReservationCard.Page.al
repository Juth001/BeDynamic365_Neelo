namespace BeDynamic.PropertyManagement;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

page 82512 "BeDyn Reservation Card"
{
    PageType = Card;
    SourceTable = "BeDyn Reservation";
    Caption = 'Reserva';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de la reserva.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad reservada.';
                }
                field("Property Name"; Rec."Property Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de la propiedad.';
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Subpropiedad reservada (solo propiedades alquiladas por subpropiedades).';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Contrato de la propiedad al que se vincula la reserva. Se asigna automáticamente si la propiedad tiene un único contrato activo y es obligatorio para confirmar la reserva.';
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
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado de la reserva. Se cambia con las acciones Confirmar, Check-In, Check-Out y Cancelar.';
                }
                field("Channel Code"; Rec."Channel Code")
                {
                    ApplicationArea = All;
                }
                field("Customer Type"; Rec."Customer Type")
                {
                    ApplicationArea = All;
                }
                field("Guest Type"; Rec."Guest Type")
                {
                    ApplicationArea = All;
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensiones';

                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Valor de la dimensión global 1 de la reserva.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Valor de la dimensión global 2 de la reserva.';
                }
            }
            group(ExternalSource)
            {
                Caption = 'Origen';

                field("External Code"; Rec."External Code")
                {
                    ApplicationArea = All;
                }
                field("External Id"; Rec."External Id")
                {
                    ApplicationArea = All;
                }
                field("External Remark"; Rec."External Remark")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }
            group(Dates)
            {
                Caption = 'Fechas';

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
                field("Check-In Time"; Rec."Check-In Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Hora prevista de check-in. Se toma por defecto de la configuración de gestión de propiedades.';
                }
                field("Check-Out Time"; Rec."Check-Out Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Hora prevista de check-out. Se toma por defecto de la configuración de gestión de propiedades.';
                }
                field("Check-In Date/Time"; Rec."Check-In Date/Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha y hora en que se realizó el check-in.';
                }
                field("Check-Out Date/Time"; Rec."Check-Out Date/Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha y hora en que se realizó el check-out.';
                }
            }
            group(Amounts)
            {
                Caption = 'Importes';

                field("Price Basis"; Rec."Price Basis")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si la reserva se valora por noche o por mes (larga estancia).';
                }
                field("Billing Moment"; Rec."Billing Moment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Momento de facturación de las reservas por noche: al check-in (prepago) o al check-out. Las reservas mensuales se facturan al confirmar (1ª mensualidad + fianza) y después mes a mes.';
                }
                field("Invoiced Until"; Rec."Invoiced Until")
                {
                    ApplicationArea = All;
                    ToolTip = 'Última noche facturada (con factura registrada) de la reserva.';
                }
                field("Rental Amount"; Rec."Rental Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Importe del alquiler calculado según la lista de precios de la propiedad. Puede modificarse manualmente.';
                }
                field("Monthly Rent"; Rec."Monthly Rent")
                {
                    ApplicationArea = All;
                }
                field("Services Amount"; Rec."Services Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Importe de los servicios adicionales.';
                }
                field(TotalAmount; Rec.GetTotalAmount())
                {
                    ApplicationArea = All;
                    Caption = 'Importe total';
                    Editable = false;
                    ToolTip = 'Importe total de la reserva (alquiler + servicios).';
                }
            }
            part(Services; "BeDyn Reservation Services")
            {
                ApplicationArea = All;
                Caption = 'Servicios adicionales';
                SubPageLink = "Reservation No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ReservationDimensions)
            {
                ApplicationArea = All;
                Caption = 'Dimensiones';
                Image = Dimensions;
                ShortcutKey = 'Alt+D';
                ToolTip = 'Consulta o modifica el conjunto de dimensiones de la reserva. La propiedad aporta las suyas y el canal se añade encima.';

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                end;
            }
            action(AvailabilityCalendar)
            {
                ApplicationArea = All;
                Caption = 'Calendario disponibilidad';
                Image = Calendar;
                ToolTip = 'Ver la disponibilidad de las subpropiedades de la propiedad en un calendario mensual antes de confirmar la reserva.';

                trigger OnAction()
                begin
                    ShowAvailabilityCalendar();
                end;
            }
            action(Deposits)
            {
                ApplicationArea = All;
                Caption = 'Fianza';
                Image = Balance;
                RunObject = page "BeDyn Deposit List";
                RunPageLink = "Reservation No." = field("No.");
                ToolTip = 'Ver la fianza de esta reserva.';
            }
            action(Invoices)
            {
                ApplicationArea = All;
                Caption = 'Facturas';
                Image = Invoice;
                RunObject = page "Sales Invoice List";
                RunPageLink = "Reservation No." = field("No.");
                ToolTip = 'Ver las facturas sin registrar generadas para esta reserva.';
            }
            action(PostedInvoices)
            {
                ApplicationArea = All;
                Caption = 'Facturas registradas';
                Image = PostedOrder;
                RunObject = page "Posted Sales Invoices";
                RunPageLink = "Reservation No." = field("No.");
                ToolTip = 'Ver las facturas registradas de esta reserva.';
            }
        }
        area(Processing)
        {
            action(ConfirmRes)
            {
                ApplicationArea = All;
                Caption = 'Confirmar';
                Image = Approve;
                ToolTip = 'Confirma la reserva tras comprobar los datos y la disponibilidad.';

                trigger OnAction()
                begin
                    ReservationMgt.ConfirmReservation(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CheckIn)
            {
                ApplicationArea = All;
                Caption = 'Check-In';
                Image = Start;
                ToolTip = 'Registra el check-in del inquilino con la fecha y hora actuales.';

                trigger OnAction()
                begin
                    ReservationMgt.CheckIn(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CheckOut)
            {
                ApplicationArea = All;
                Caption = 'Check-Out';
                Image = Stop;
                ToolTip = 'Registra el check-out del inquilino con la fecha y hora actuales.';

                trigger OnAction()
                begin
                    ReservationMgt.CheckOut(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CancelRes)
            {
                ApplicationArea = All;
                Caption = 'Cancelar reserva';
                Image = Cancel;
                ToolTip = 'Cancela la reserva.';

                trigger OnAction()
                begin
                    if not Confirm(CancelQst, false, Rec."No.") then
                        exit;
                    ReservationMgt.CancelReservation(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ConfirmRes_Promoted; ConfirmRes)
                {
                }
                actionref(CheckIn_Promoted; CheckIn)
                {
                }
                actionref(CheckOut_Promoted; CheckOut)
                {
                }
                actionref(CancelRes_Promoted; CancelRes)
                {
                }
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

    var
        ReservationMgt: Codeunit "BeDyn Prop. Reservation Mgt.";
        CancelQst: Label '¿Desea cancelar la reserva %1?', Comment = '%1 = Nº reserva';
}
