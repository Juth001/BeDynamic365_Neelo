namespace BeDynamic.PropertyManagement;

page 82532 "BeDyn Room Avail. Calendar"
{
    PageType = Worksheet;
    SourceTable = "BeDyn Property Room";
    Caption = 'Calendario de disponibilidad';
    UsageCategory = Tasks;
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Options)
            {
                Caption = 'Opciones';

                field(MonthCtrl; MonthNo)
                {
                    ApplicationArea = All;
                    Caption = 'Mes';
                    ToolTip = 'Mes que se muestra en el calendario (1-12).';

                    trigger OnValidate()
                    begin
                        CheckPeriod();
                        UpdateMonth();
                        CurrPage.Update(false);
                    end;
                }
                field(YearCtrl; YearNo)
                {
                    ApplicationArea = All;
                    Caption = 'Año';
                    ToolTip = 'Año que se muestra en el calendario.';

                    trigger OnValidate()
                    begin
                        CheckPeriod();
                        UpdateMonth();
                        CurrPage.Update(false);
                    end;
                }
                field(PeriodName; Format(MonthStartDate, 0, MonthNameFormatTok))
                {
                    ApplicationArea = All;
                    Caption = 'Periodo';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Mes y año que se están mostrando.';
                }
            }
            repeater(Rooms)
            {
                FreezeColumn = Description;

                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Propiedad a la que pertenece la subpropiedad.';
                    Visible = false;
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Número o código de la subpropiedad.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Descripción de la subpropiedad.';
                }
                field(D1; DayCellText[1])
                {
                    ApplicationArea = All;
                    Caption = '1';
                    CaptionClass = '3,' + DayCaption[1];
                    Editable = false;
                    StyleExpr = DayStyle1;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(1);
                    end;
                }
                field(D2; DayCellText[2])
                {
                    ApplicationArea = All;
                    Caption = '2';
                    CaptionClass = '3,' + DayCaption[2];
                    Editable = false;
                    StyleExpr = DayStyle2;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(2);
                    end;
                }
                field(D3; DayCellText[3])
                {
                    ApplicationArea = All;
                    Caption = '3';
                    CaptionClass = '3,' + DayCaption[3];
                    Editable = false;
                    StyleExpr = DayStyle3;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(3);
                    end;
                }
                field(D4; DayCellText[4])
                {
                    ApplicationArea = All;
                    Caption = '4';
                    CaptionClass = '3,' + DayCaption[4];
                    Editable = false;
                    StyleExpr = DayStyle4;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(4);
                    end;
                }
                field(D5; DayCellText[5])
                {
                    ApplicationArea = All;
                    Caption = '5';
                    CaptionClass = '3,' + DayCaption[5];
                    Editable = false;
                    StyleExpr = DayStyle5;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(5);
                    end;
                }
                field(D6; DayCellText[6])
                {
                    ApplicationArea = All;
                    Caption = '6';
                    CaptionClass = '3,' + DayCaption[6];
                    Editable = false;
                    StyleExpr = DayStyle6;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(6);
                    end;
                }
                field(D7; DayCellText[7])
                {
                    ApplicationArea = All;
                    Caption = '7';
                    CaptionClass = '3,' + DayCaption[7];
                    Editable = false;
                    StyleExpr = DayStyle7;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(7);
                    end;
                }
                field(D8; DayCellText[8])
                {
                    ApplicationArea = All;
                    Caption = '8';
                    CaptionClass = '3,' + DayCaption[8];
                    Editable = false;
                    StyleExpr = DayStyle8;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(8);
                    end;
                }
                field(D9; DayCellText[9])
                {
                    ApplicationArea = All;
                    Caption = '9';
                    CaptionClass = '3,' + DayCaption[9];
                    Editable = false;
                    StyleExpr = DayStyle9;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(9);
                    end;
                }
                field(D10; DayCellText[10])
                {
                    ApplicationArea = All;
                    Caption = '10';
                    CaptionClass = '3,' + DayCaption[10];
                    Editable = false;
                    StyleExpr = DayStyle10;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(10);
                    end;
                }
                field(D11; DayCellText[11])
                {
                    ApplicationArea = All;
                    Caption = '11';
                    CaptionClass = '3,' + DayCaption[11];
                    Editable = false;
                    StyleExpr = DayStyle11;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(11);
                    end;
                }
                field(D12; DayCellText[12])
                {
                    ApplicationArea = All;
                    Caption = '12';
                    CaptionClass = '3,' + DayCaption[12];
                    Editable = false;
                    StyleExpr = DayStyle12;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(12);
                    end;
                }
                field(D13; DayCellText[13])
                {
                    ApplicationArea = All;
                    Caption = '13';
                    CaptionClass = '3,' + DayCaption[13];
                    Editable = false;
                    StyleExpr = DayStyle13;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(13);
                    end;
                }
                field(D14; DayCellText[14])
                {
                    ApplicationArea = All;
                    Caption = '14';
                    CaptionClass = '3,' + DayCaption[14];
                    Editable = false;
                    StyleExpr = DayStyle14;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(14);
                    end;
                }
                field(D15; DayCellText[15])
                {
                    ApplicationArea = All;
                    Caption = '15';
                    CaptionClass = '3,' + DayCaption[15];
                    Editable = false;
                    StyleExpr = DayStyle15;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(15);
                    end;
                }
                field(D16; DayCellText[16])
                {
                    ApplicationArea = All;
                    Caption = '16';
                    CaptionClass = '3,' + DayCaption[16];
                    Editable = false;
                    StyleExpr = DayStyle16;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(16);
                    end;
                }
                field(D17; DayCellText[17])
                {
                    ApplicationArea = All;
                    Caption = '17';
                    CaptionClass = '3,' + DayCaption[17];
                    Editable = false;
                    StyleExpr = DayStyle17;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(17);
                    end;
                }
                field(D18; DayCellText[18])
                {
                    ApplicationArea = All;
                    Caption = '18';
                    CaptionClass = '3,' + DayCaption[18];
                    Editable = false;
                    StyleExpr = DayStyle18;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(18);
                    end;
                }
                field(D19; DayCellText[19])
                {
                    ApplicationArea = All;
                    Caption = '19';
                    CaptionClass = '3,' + DayCaption[19];
                    Editable = false;
                    StyleExpr = DayStyle19;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(19);
                    end;
                }
                field(D20; DayCellText[20])
                {
                    ApplicationArea = All;
                    Caption = '20';
                    CaptionClass = '3,' + DayCaption[20];
                    Editable = false;
                    StyleExpr = DayStyle20;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(20);
                    end;
                }
                field(D21; DayCellText[21])
                {
                    ApplicationArea = All;
                    Caption = '21';
                    CaptionClass = '3,' + DayCaption[21];
                    Editable = false;
                    StyleExpr = DayStyle21;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(21);
                    end;
                }
                field(D22; DayCellText[22])
                {
                    ApplicationArea = All;
                    Caption = '22';
                    CaptionClass = '3,' + DayCaption[22];
                    Editable = false;
                    StyleExpr = DayStyle22;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(22);
                    end;
                }
                field(D23; DayCellText[23])
                {
                    ApplicationArea = All;
                    Caption = '23';
                    CaptionClass = '3,' + DayCaption[23];
                    Editable = false;
                    StyleExpr = DayStyle23;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(23);
                    end;
                }
                field(D24; DayCellText[24])
                {
                    ApplicationArea = All;
                    Caption = '24';
                    CaptionClass = '3,' + DayCaption[24];
                    Editable = false;
                    StyleExpr = DayStyle24;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(24);
                    end;
                }
                field(D25; DayCellText[25])
                {
                    ApplicationArea = All;
                    Caption = '25';
                    CaptionClass = '3,' + DayCaption[25];
                    Editable = false;
                    StyleExpr = DayStyle25;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(25);
                    end;
                }
                field(D26; DayCellText[26])
                {
                    ApplicationArea = All;
                    Caption = '26';
                    CaptionClass = '3,' + DayCaption[26];
                    Editable = false;
                    StyleExpr = DayStyle26;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(26);
                    end;
                }
                field(D27; DayCellText[27])
                {
                    ApplicationArea = All;
                    Caption = '27';
                    CaptionClass = '3,' + DayCaption[27];
                    Editable = false;
                    StyleExpr = DayStyle27;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(27);
                    end;
                }
                field(D28; DayCellText[28])
                {
                    ApplicationArea = All;
                    Caption = '28';
                    CaptionClass = '3,' + DayCaption[28];
                    Editable = false;
                    StyleExpr = DayStyle28;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(28);
                    end;
                }
                field(D29; DayCellText[29])
                {
                    ApplicationArea = All;
                    Caption = '29';
                    CaptionClass = '3,' + DayCaption[29];
                    Editable = false;
                    StyleExpr = DayStyle29;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';
                    Visible = Day29Visible;

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(29);
                    end;
                }
                field(D30; DayCellText[30])
                {
                    ApplicationArea = All;
                    Caption = '30';
                    CaptionClass = '3,' + DayCaption[30];
                    Editable = false;
                    StyleExpr = DayStyle30;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';
                    Visible = Day30Visible;

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(30);
                    end;
                }
                field(D31; DayCellText[31])
                {
                    ApplicationArea = All;
                    Caption = '31';
                    CaptionClass = '3,' + DayCaption[31];
                    Editable = false;
                    StyleExpr = DayStyle31;
                    ToolTip = 'Verde ■: disponible. Rojo ■: reservado. Amarillo □: pendiente de confirmar. Haga clic para ver el detalle.';
                    Visible = Day31Visible;

                    trigger OnDrillDown()
                    begin
                        DayDrillDown(31);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PreviousMonth)
            {
                ApplicationArea = All;
                Caption = 'Mes anterior';
                Image = PreviousRecord;
                ToolTip = 'Muestra el mes anterior.';

                trigger OnAction()
                begin
                    SetMonthFromDate(CalcDate('<-1M>', MonthStartDate));
                end;
            }
            action(CurrentMonth)
            {
                ApplicationArea = All;
                Caption = 'Mes actual';
                Image = Refresh;
                ToolTip = 'Vuelve al mes de la fecha de trabajo.';

                trigger OnAction()
                begin
                    SetMonthFromDate(WorkDate());
                end;
            }
            action(NextMonth)
            {
                ApplicationArea = All;
                Caption = 'Mes siguiente';
                Image = NextRecord;
                ToolTip = 'Muestra el mes siguiente.';

                trigger OnAction()
                begin
                    SetMonthFromDate(CalcDate('<1M>', MonthStartDate));
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(PreviousMonth_Promoted; PreviousMonth)
                {
                }
                actionref(CurrentMonth_Promoted; CurrentMonth)
                {
                }
                actionref(NextMonth_Promoted; NextMonth)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if InitialDate = 0D then
            InitialDate := WorkDate();
        MonthNo := Date2DMY(InitialDate, 2);
        YearNo := Date2DMY(InitialDate, 3);
        UpdateMonth();
    end;

    trigger OnAfterGetRecord()
    begin
        BuildRoomCalendar();
    end;

    // Permite abrir el calendario posicionado en el mes de una fecha concreta (p. ej. la fecha de inicio de una reserva).
    procedure SetInitialDate(NewDate: Date)
    begin
        if NewDate <> 0D then
            InitialDate := NewDate;
    end;

    local procedure SetMonthFromDate(NewDate: Date)
    begin
        MonthNo := Date2DMY(NewDate, 2);
        YearNo := Date2DMY(NewDate, 3);
        UpdateMonth();
        CurrPage.Update(false);
    end;

    local procedure CheckPeriod()
    begin
        if (MonthNo < 1) or (MonthNo > 12) then
            Error(InvalidMonthErr);
        if (YearNo < 1900) or (YearNo > 2999) then
            Error(InvalidYearErr);
    end;

    local procedure UpdateMonth()
    var
        DayNo: Integer;
    begin
        MonthStartDate := DMY2Date(1, MonthNo, YearNo);
        MonthEndDate := CalcDate('<CM>', MonthStartDate);
        DaysInMonth := Date2DMY(MonthEndDate, 1);
        Day29Visible := DaysInMonth >= 29;
        Day30Visible := DaysInMonth >= 30;
        Day31Visible := DaysInMonth = 31;
        for DayNo := 1 to ArrayLen(DayCaption) do
            if DayNo <= DaysInMonth then
                DayCaption[DayNo] := GetWeekdayLetter(MonthStartDate + DayNo - 1) + ' ' + Format(DayNo)
            else
                DayCaption[DayNo] := Format(DayNo);
    end;

    // Inicial del día de la semana según la convención española: L M X J V S D.
    local procedure GetWeekdayLetter(TheDate: Date): Text
    begin
        exit(CopyStr(WeekdayLettersTxt, Date2DWY(TheDate, 1), 1));
    end;

    // Pinta los días del mes para la subpropiedad actual: verde (disponible), rojo (reservada),
    // amarillo (reserva pendiente). Las reservas de la propiedad completa (sin subpropiedad) bloquean todas las subpropiedades.
    // La fecha de fin es el día de salida, por lo que esa noche queda disponible (mismo criterio que CheckAvailability).
    local procedure BuildRoomCalendar()
    var
        Reservation: Record "BeDyn Reservation";
        DayNo: Integer;
        FirstDayNo: Integer;
        LastDayNo: Integer;
    begin
        for DayNo := 1 to ArrayLen(DayCellText) do
            if DayNo <= DaysInMonth then begin
                DayCellText[DayNo] := MarkerTok;
                DayCellStyle[DayNo] := FavorableTok;
            end else begin
                DayCellText[DayNo] := '';
                DayCellStyle[DayNo] := SubordinateTok;
            end;

        Reservation.SetCurrentKey("Property No.", "Room No.", "Start Date");
        Reservation.SetRange("Property No.", Rec."Property No.");
        Reservation.SetFilter("Room No.", '%1|%2', Rec."Room No.", '');
        Reservation.SetFilter(Status, '<>%1', Reservation.Status::Cancelled);
        Reservation.SetFilter("Start Date", '<>%1&<=%2', 0D, MonthEndDate);
        Reservation.SetFilter("End Date", '>%1', MonthStartDate);
        if Reservation.FindSet() then
            repeat
                if Reservation."Start Date" <= MonthStartDate then
                    FirstDayNo := 1
                else
                    FirstDayNo := Reservation."Start Date" - MonthStartDate + 1;
                if Reservation."End Date" > MonthEndDate then
                    LastDayNo := DaysInMonth
                else
                    LastDayNo := Reservation."End Date" - MonthStartDate;
                for DayNo := FirstDayNo to LastDayNo do
                    MarkDayReserved(DayNo, Reservation.Status);
            until Reservation.Next() = 0;

        CopyStylesToControls();
    end;

    // StyleExpr no admite acceso a arrays (AL0322), por lo que cada columna necesita su propia variable escalar.
    local procedure CopyStylesToControls()
    begin
        DayStyle1 := DayCellStyle[1];
        DayStyle2 := DayCellStyle[2];
        DayStyle3 := DayCellStyle[3];
        DayStyle4 := DayCellStyle[4];
        DayStyle5 := DayCellStyle[5];
        DayStyle6 := DayCellStyle[6];
        DayStyle7 := DayCellStyle[7];
        DayStyle8 := DayCellStyle[8];
        DayStyle9 := DayCellStyle[9];
        DayStyle10 := DayCellStyle[10];
        DayStyle11 := DayCellStyle[11];
        DayStyle12 := DayCellStyle[12];
        DayStyle13 := DayCellStyle[13];
        DayStyle14 := DayCellStyle[14];
        DayStyle15 := DayCellStyle[15];
        DayStyle16 := DayCellStyle[16];
        DayStyle17 := DayCellStyle[17];
        DayStyle18 := DayCellStyle[18];
        DayStyle19 := DayCellStyle[19];
        DayStyle20 := DayCellStyle[20];
        DayStyle21 := DayCellStyle[21];
        DayStyle22 := DayCellStyle[22];
        DayStyle23 := DayCellStyle[23];
        DayStyle24 := DayCellStyle[24];
        DayStyle25 := DayCellStyle[25];
        DayStyle26 := DayCellStyle[26];
        DayStyle27 := DayCellStyle[27];
        DayStyle28 := DayCellStyle[28];
        DayStyle29 := DayCellStyle[29];
        DayStyle30 := DayCellStyle[30];
        DayStyle31 := DayCellStyle[31];
    end;

    // Una reserva pendiente (amarillo, cuadro hueco) nunca sobrescribe una reserva firme
    // (rojo, cuadro sólido) en el mismo día. El marcador distinto ayuda a diferenciar las
    // pendientes de las disponibles, ya que los colores de los estilos de BC son fijos.
    local procedure MarkDayReserved(DayNo: Integer; ReservationStatus: Enum "BeDyn Prop. Reservation Status")
    begin
        if ReservationStatus = ReservationStatus::Pending then begin
            if DayCellStyle[DayNo] = FavorableTok then begin
                DayCellStyle[DayNo] := AmbiguousTok;
                DayCellText[DayNo] := PendingMarkerTok;
            end;
        end else begin
            DayCellStyle[DayNo] := UnfavorableTok;
            DayCellText[DayNo] := MarkerTok;
        end;
    end;

    local procedure DayDrillDown(DayNo: Integer)
    var
        Reservation: Record "BeDyn Reservation";
        SelectedDate: Date;
    begin
        if DayNo > DaysInMonth then
            exit;
        SelectedDate := MonthStartDate + DayNo - 1;
        Reservation.SetRange("Property No.", Rec."Property No.");
        Reservation.SetFilter("Room No.", '%1|%2', Rec."Room No.", '');
        Reservation.SetFilter(Status, '<>%1', Reservation.Status::Cancelled);
        Reservation.SetFilter("Start Date", '<>%1&<=%2', 0D, SelectedDate);
        Reservation.SetFilter("End Date", '>%1', SelectedDate);
        if Reservation.IsEmpty() then begin
            Message(DayAvailableMsg, Rec."Room No.", SelectedDate);
            exit;
        end;
        Page.Run(Page::"BeDyn Reservation List", Reservation);
    end;

    var
        MonthNo: Integer;
        YearNo: Integer;
        InitialDate: Date;
        MonthStartDate: Date;
        MonthEndDate: Date;
        DaysInMonth: Integer;
        Day29Visible: Boolean;
        Day30Visible: Boolean;
        Day31Visible: Boolean;
        DayCellText: array[31] of Text[1];
        DayCellStyle: array[31] of Text;
        DayCaption: array[31] of Text;
        DayStyle1, DayStyle2, DayStyle3, DayStyle4, DayStyle5, DayStyle6, DayStyle7, DayStyle8 : Text;
        DayStyle9, DayStyle10, DayStyle11, DayStyle12, DayStyle13, DayStyle14, DayStyle15, DayStyle16 : Text;
        DayStyle17, DayStyle18, DayStyle19, DayStyle20, DayStyle21, DayStyle22, DayStyle23, DayStyle24 : Text;
        DayStyle25, DayStyle26, DayStyle27, DayStyle28, DayStyle29, DayStyle30, DayStyle31 : Text;
        WeekdayLettersTxt: Label 'LMXJVSD', Comment = 'Iniciales de lunes a domingo';
        MarkerTok: Label '■', Locked = true;
        PendingMarkerTok: Label '□', Locked = true;
        FavorableTok: Label 'Favorable', Locked = true;
        UnfavorableTok: Label 'Unfavorable', Locked = true;
        AmbiguousTok: Label 'Ambiguous', Locked = true;
        SubordinateTok: Label 'Subordinate', Locked = true;
        MonthNameFormatTok: Label '<Month Text> <Year4>', Locked = true;
        InvalidMonthErr: Label 'El mes debe estar entre 1 y 12.';
        InvalidYearErr: Label 'El año debe estar entre 1900 y 2999.';
        DayAvailableMsg: Label 'La subpropiedad %1 está disponible el %2.', Comment = '%1 = Nº subpropiedad, %2 = Fecha';
}
