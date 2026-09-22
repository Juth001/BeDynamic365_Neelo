namespace BeDynamic.PropertyManagement;

table 82508 "BeDyn Reservation Service"
{
    Caption = 'Servicio de reserva';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reservation No."; Code[20])
        {
            Caption = 'Nº reserva';
            TableRelation = "BeDyn Reservation";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        field(3; "Service Code"; Code[20])
        {
            Caption = 'Código servicio';
            TableRelation = "BeDyn Property Service";
            NotBlank = true;

            trigger OnValidate()
            var
                PropertyService: Record "BeDyn Property Service";
            begin
                if "Service Code" = '' then
                    Description := ''
                else begin
                    PropertyService.Get("Service Code");
                    Description := PropertyService.Description;
                end;
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Descripción';
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Cantidad';
            InitValue = 1;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcAmount();
            end;
        }
        field(6; "Unit Price"; Decimal)
        {
            Caption = 'Precio unitario';
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcAmount();
            end;
        }
        field(7; Amount; Decimal)
        {
            Caption = 'Importe';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Reservation No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
    }

    local procedure CalcAmount()
    begin
        Amount := Quantity * "Unit Price";
    end;
}
