namespace BeDynamic.PropertyManagement;

page 82539 "BeDyn Property RC Headline"
{
    Caption = 'Titular';
    PageType = HeadlinePart;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            field(Greeting; GreetingTxt)
            {
                ApplicationArea = All;
                Caption = 'Saludo';
                Editable = false;
            }
            field(Arrivals; ArrivalsTxt)
            {
                ApplicationArea = All;
                Caption = 'Llegadas';
                Editable = false;

                trigger OnDrillDown()
                var
                    Reservation: Record "BeDyn Reservation";
                begin
                    Reservation.SetFilter(Status, '%1|%2', Reservation.Status::Pending, Reservation.Status::Confirmed);
                    Reservation.SetRange("Start Date", WorkDate());
                    Page.Run(Page::"BeDyn Reservation List", Reservation);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Reservation: Record "BeDyn Reservation";
        ArrivalsCount: Integer;
    begin
        GreetingTxt := WelcomeMsg;
        Reservation.SetFilter(Status, '%1|%2', Reservation.Status::Pending, Reservation.Status::Confirmed);
        Reservation.SetRange("Start Date", WorkDate());
        ArrivalsCount := Reservation.Count();
        if ArrivalsCount = 0 then
            ArrivalsTxt := NoArrivalsMsg
        else
            ArrivalsTxt := StrSubstNo(ArrivalsMsg, ArrivalsCount);
    end;

    var
        GreetingTxt: Text;
        ArrivalsTxt: Text;
        WelcomeMsg: Label 'Bienvenido a la gestión de propiedades';
        NoArrivalsMsg: Label 'Hoy no hay llegadas previstas';
        ArrivalsMsg: Label 'Hoy hay %1 llegadas previstas', Comment = '%1 = número de reservas que empiezan hoy';
}
