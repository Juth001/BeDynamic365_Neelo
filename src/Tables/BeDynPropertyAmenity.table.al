namespace BeDynamic.PropertyManagement;

table 82518 "BeDyn Property Amenity"
{
    Caption = 'Amenity de propiedad';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Property No."; Code[20])
        {
            Caption = 'Nº propiedad';
            TableRelation = "BeDyn Property";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        field(3; Location; Enum "BeDyn Amenity Location")
        {
            Caption = 'Ubicación';

            trigger OnValidate()
            begin
                if Location = Location::"Common Area" then
                    "Room No." := '';
            end;
        }
        field(4; "Room No."; Code[20])
        {
            Caption = 'Nº subpropiedad';
            TableRelation = "BeDyn Property Room"."Room No." where("Property No." = field("Property No."));

            trigger OnValidate()
            begin
                if "Room No." <> '' then
                    Location := Location::Room
                else
                    Location := Location::"Common Area";
            end;
        }
        field(5; "Amenity Code"; Code[20])
        {
            Caption = 'Cód. amenity';
            TableRelation = "BeDyn Amenity";
            NotBlank = true;

            trigger OnValidate()
            var
                Amenity: Record "BeDyn Amenity";
            begin
                if "Amenity Code" = '' then begin
                    Description := '';
                    exit;
                end;
                Amenity.Get("Amenity Code");
                Description := Amenity.Description;
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Descripción';
        }
        field(7; "Amenity Type Code"; Code[20])
        {
            Caption = 'Cód. tipo amenity';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Amenity"."Amenity Type Code" where("Code" = field("Amenity Code")));
            Editable = false;
        }
        field(8; Brand; Text[50])
        {
            Caption = 'Marca';
        }
        field(9; "Serial No."; Code[50])
        {
            Caption = 'Nº de serie';
        }
        field(10; Status; Enum "BeDyn Amenity Status")
        {
            Caption = 'Estado';
        }
    }

    keys
    {
        key(PK; "Property No.", "Line No.")
        {
            Clustered = true;
        }
        key(Room; "Property No.", "Room No.")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Room No." <> '' then
            Location := Location::Room;
        CheckRoomLocation();
    end;

    trigger OnModify()
    begin
        CheckRoomLocation();
    end;

    local procedure CheckRoomLocation()
    begin
        if Location = Location::Room then
            TestField("Room No.")
        else
            TestField("Room No.", '');
    end;
}
