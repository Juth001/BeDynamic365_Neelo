namespace BeDynamic.PropertyManagement;

using Microsoft.Foundation.NoSeries;

table 82504 "BeDyn Property Contract"
{
    Caption = 'Contrato de propiedad';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Property Contract List";
    DrillDownPageId = "BeDyn Property Contract List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Nº';

            trigger OnValidate()
            var
                PropertySetup: Record "BeDyn Property Mgt. Setup";
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    PropertySetup.GetInstance();
                    NoSeries.TestManual(PropertySetup."Contract Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Contract Type"; Enum "BeDyn Contract Type")
        {
            Caption = 'Tipo de contrato';

            trigger OnValidate()
            begin
                CheckOwnerRole();
            end;
        }
        field(3; "Owner No."; Code[20])
        {
            Caption = 'Nº propietario';
            TableRelation = "BeDyn Property Owner";
            NotBlank = true;

            trigger OnValidate()
            begin
                if "Owner No." <> xRec."Owner No." then
                    "Property No." := '';
                CheckOwnerRole();
            end;
        }
        field(4; "Property No."; Code[20])
        {
            Caption = 'Nº propiedad';
            TableRelation = "BeDyn Property"."No." where("Owner No." = field("Owner No."));
            NotBlank = true;
        }
        field(5; "Start Date"; Date)
        {
            Caption = 'Fecha inicio';

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
        field(6; "End Date"; Date)
        {
            Caption = 'Fecha fin';

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
        field(7; "Agreed Rental Amount"; Decimal)
        {
            Caption = 'Importe alquiler pactado (mensual)';
            MinValue = 0;
        }
        field(8; Status; Enum "BeDyn Contract Status")
        {
            Caption = 'Estado';

            trigger OnValidate()
            begin
                if Status = Status::Active then begin
                    TestField("Contract Type");
                    TestField("Owner No.");
                    TestField("Property No.");
                    TestField("Start Date");
                    TestField("Agreed Rental Amount");
                    CheckOwnerRole();
                end;
            end;
        }
        field(9; "Owner Name"; Text[100])
        {
            Caption = 'Nombre propietario';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Property Owner".Name where("No." = field("Owner No.")));
            Editable = false;
        }
        field(10; "Property Name"; Text[100])
        {
            Caption = 'Nombre propiedad';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Property".Name where("No." = field("Property No.")));
            Editable = false;
        }
        field(11; "No. Series"; Code[20])
        {
            Caption = 'Nos. serie';
            TableRelation = "No. Series";
            Editable = false;
        }
        field(12; "Owner Vendor No."; Code[20])
        {
            Caption = 'Nº proveedor del propietario';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Property Owner"."Vendor No." where("No." = field("Owner No.")));
            Editable = false;
        }
        field(13; "Owner Customer No."; Code[20])
        {
            Caption = 'Nº cliente del propietario';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Property Owner"."Customer No." where("No." = field("Owner No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Property; "Property No.", "Start Date")
        {
        }
    }

    trigger OnInsert()
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            PropertySetup.GetInstance();
            PropertySetup.TestField("Contract Nos.");
            "No. Series" := PropertySetup."Contract Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnDelete()
    var
        Reservation: Record "BeDyn Reservation";
    begin
        Reservation.SetRange("Contract No.", "No.");
        if not Reservation.IsEmpty() then
            Error(HasReservationsErr, "No.");
    end;

    procedure AssistEdit(OldPropertyContract: Record "BeDyn Property Contract"): Boolean
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PropertySetup.GetInstance();
        PropertySetup.TestField("Contract Nos.");
        if NoSeries.LookupRelatedNoSeries(PropertySetup."Contract Nos.", OldPropertyContract."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    // Explotación: el propietario nos factura => debe estar vinculado a un proveedor.
    // Gestión: le facturamos el fee de gestión => debe estar vinculado a un cliente.
    local procedure CheckOwnerRole()
    var
        PropertyOwner: Record "BeDyn Property Owner";
    begin
        if "Owner No." = '' then
            exit;
        PropertyOwner.Get("Owner No.");
        case "Contract Type" of
            "BeDyn Contract Type"::Exploitation:
                if PropertyOwner."Vendor No." = '' then
                    Error(OwnerNeedsVendorErr, "Owner No.");
            "BeDyn Contract Type"::Management:
                if PropertyOwner."Customer No." = '' then
                    Error(OwnerNeedsCustomerErr, "Owner No.");
        end;
    end;

    local procedure CheckDates()
    begin
        if ("Start Date" <> 0D) and ("End Date" <> 0D) and ("End Date" < "Start Date") then
            Error(InvalidDatesErr);
    end;

    procedure GetInvoicedAmount(): Decimal
    var
        Reservation: Record "BeDyn Reservation";
        Total: Decimal;
    begin
        if "Property No." = '' then
            exit(0);

        Reservation.SetRange("Property No.", "Property No.");
        Reservation.SetFilter(Status, '<>%1', Reservation.Status::Cancelled);
        if ("Start Date" <> 0D) and ("End Date" <> 0D) then
            Reservation.SetRange("Start Date", "Start Date", "End Date")
        else
            if "Start Date" <> 0D then
                Reservation.SetFilter("Start Date", '>=%1', "Start Date")
            else
                if "End Date" <> 0D then
                    Reservation.SetFilter("Start Date", '<=%1', "End Date");

        if Reservation.FindSet() then
            repeat
                Total += Reservation.GetTotalAmount();
            until Reservation.Next() = 0;
        exit(Total);
    end;

    // Fee de gestión = lo facturado por la propiedad - importe de alquiler pactado con el propietario.
    procedure GetManagementFee(): Decimal
    begin
        exit(GetInvoicedAmount() - "Agreed Rental Amount");
    end;

    var
        InvalidDatesErr: Label 'La fecha de fin no puede ser anterior a la fecha de inicio.';
        HasReservationsErr: Label 'No se puede eliminar el contrato %1 porque tiene reservas vinculadas.', Comment = '%1 = Nº contrato';
        OwnerNeedsVendorErr: Label 'En un contrato de explotación el propietario nos factura el alquiler, por lo que debe tener un proveedor asociado. Asigne el Nº proveedor en la ficha del propietario %1.', Comment = '%1 = Nº propietario';
        OwnerNeedsCustomerErr: Label 'En un contrato de gestión facturamos el fee al propietario, por lo que debe tener un cliente asociado. Asigne el Nº cliente en la ficha del propietario %1.', Comment = '%1 = Nº propietario';
}
