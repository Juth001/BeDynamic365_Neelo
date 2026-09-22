namespace BeDynamic.PropertyManagement;

codeunit 82500 "BeDyn Prop. Reservation Mgt."
{
    var
        PropertyBillingMgt: Codeunit "BeDyn Property Billing Mgt.";
        CannotCancelErr: Label 'No se puede cancelar la reserva %1 porque ya tiene el check-out realizado.', Comment = '%1 = Nº reserva';
        NotAvailableErr: Label 'La propiedad %1 no está disponible en las fechas indicadas. Conflicto con la reserva %2.', Comment = '%1 = Nº propiedad, %2 = Nº reserva';
        NoRentalAmountErr: Label 'La reserva %1 no tiene importe de alquiler. Defina la lista de precios de la propiedad o introduzca el importe manualmente.', Comment = '%1 = Nº reserva';

    procedure ConfirmReservation(var Reservation: Record "BeDyn Reservation")
    begin
        Reservation.TestField(Status, Reservation.Status::Pending);
        Reservation.TestField("Property No.");
        Reservation.TestField("Contract No.");
        Reservation.TestField("Tenant No.");
        Reservation.TestField("Start Date");
        Reservation.TestField("End Date");
        if Reservation."Rental Amount" = 0 then
            Error(NoRentalAmountErr, Reservation."No.");
        CheckRoomRequirement(Reservation);
        CheckAvailability(Reservation);
        Reservation.Status := Reservation.Status::Confirmed;
        Reservation.Modify(true);
        PropertyBillingMgt.OnReservationConfirmed(Reservation);
    end;

    procedure CheckIn(var Reservation: Record "BeDyn Reservation")
    begin
        Reservation.TestField(Status, Reservation.Status::Confirmed);
        Reservation."Check-In Date/Time" := CurrentDateTime();
        Reservation.Status := Reservation.Status::CheckedIn;
        Reservation.Modify(true);
        if Reservation."Price Basis" = Reservation."Price Basis"::"Per Night" then
            PropertyBillingMgt.OnCheckIn(Reservation);
    end;

    procedure CheckOut(var Reservation: Record "BeDyn Reservation")
    begin
        Reservation.TestField(Status, Reservation.Status::CheckedIn);
        Reservation."Check-Out Date/Time" := CurrentDateTime();
        Reservation.Status := Reservation.Status::CheckedOut;
        Reservation.Modify(true);
        if Reservation."Price Basis" = Reservation."Price Basis"::"Per Night" then
            PropertyBillingMgt.OnCheckOut(Reservation);
    end;

    procedure CancelReservation(var Reservation: Record "BeDyn Reservation")
    begin
        if Reservation.Status = Reservation.Status::CheckedOut then
            Error(CannotCancelErr, Reservation."No.");
        Reservation.Status := Reservation.Status::Cancelled;
        Reservation.Modify(true);
    end;

    procedure CheckAvailability(Reservation: Record "BeDyn Reservation")
    var
        OtherReservation: Record "BeDyn Reservation";
    begin
        OtherReservation.SetFilter("No.", '<>%1', Reservation."No.");
        OtherReservation.SetRange("Property No.", Reservation."Property No.");
        OtherReservation.SetFilter(Status, '<>%1', OtherReservation.Status::Cancelled);
        OtherReservation.SetFilter("Start Date", '<%1', Reservation."End Date");
        OtherReservation.SetFilter("End Date", '>%1', Reservation."Start Date");
        // Reserva de subpropiedad: choca con la misma subpropiedad o con reservas de la propiedad completa.
        // Reserva de propiedad completa: choca con cualquier reserva de la propiedad (sin filtro adicional).
        if Reservation."Room No." <> '' then
            OtherReservation.SetFilter("Room No.", '%1|%2', Reservation."Room No.", '');
        if OtherReservation.FindFirst() then
            Error(NotAvailableErr, Reservation."Property No.", OtherReservation."No.");
    end;

    local procedure CheckRoomRequirement(Reservation: Record "BeDyn Reservation")
    var
        Property: Record "BeDyn Property";
    begin
        Property.Get(Reservation."Property No.");
        if Property."Rental Type" = Property."Rental Type"::"By Room" then
            Reservation.TestField("Room No.")
        else
            Reservation.TestField("Room No.", '');
    end;
}
