namespace BeDynamic.PropertyManagement;

table 82520 "BeDyn Property Cue"
{
    Caption = 'Indicadores de propiedades';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(2; Properties; Integer)
        {
            Caption = 'Propiedades';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Property");
            Editable = false;
        }
        field(3; "Active Contracts"; Integer)
        {
            Caption = 'Contratos activos';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Property Contract" where(Status = const(Active)));
            Editable = false;
        }
        field(4; "Draft Contracts"; Integer)
        {
            Caption = 'Contratos en borrador';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Property Contract" where(Status = const(Draft)));
            Editable = false;
        }
        field(5; "Contracts Expiring"; Integer)
        {
            Caption = 'Contratos que vencen';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Property Contract" where(Status = const(Active), "End Date" = field("Date Filter")));
            Editable = false;
        }
        field(6; "Pending Reservations"; Integer)
        {
            Caption = 'Reservas pendientes';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Reservation" where(Status = const(Pending)));
            Editable = false;
        }
        field(7; "Confirmed Reservations"; Integer)
        {
            Caption = 'Reservas confirmadas';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Reservation" where(Status = const(Confirmed)));
            Editable = false;
        }
        field(8; "Arrivals Today"; Integer)
        {
            Caption = 'Llegadas hoy';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Reservation" where(Status = filter(Pending | Confirmed), "Start Date" = field("Today Filter")));
            Editable = false;
        }
        field(9; "Departures Today"; Integer)
        {
            Caption = 'Salidas hoy';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Reservation" where(Status = const(CheckedIn), "End Date" = field("Today Filter")));
            Editable = false;
        }
        field(10; "Guests Checked In"; Integer)
        {
            Caption = 'Inquilinos alojados';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Reservation" where(Status = const(CheckedIn)));
            Editable = false;
        }
        field(11; "Pending Deposits"; Integer)
        {
            Caption = 'Fianzas pendientes';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Deposit" where(Status = const(Pending)));
            Editable = false;
        }
        field(12; "Deposits Collected"; Integer)
        {
            Caption = 'Fianzas cobradas';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Deposit" where(Status = const(Collected)));
            Editable = false;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Filtro fecha';
            FieldClass = FlowFilter;
        }
        field(21; "Today Filter"; Date)
        {
            Caption = 'Filtro hoy';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
