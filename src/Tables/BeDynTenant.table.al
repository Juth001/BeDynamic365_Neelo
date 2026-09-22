namespace BeDynamic.PropertyManagement;

using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;

table 82505 "BeDyn Tenant"
{
    Caption = 'Inquilino';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Tenant List";
    DrillDownPageId = "BeDyn Tenant List";

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
                    NoSeries.TestManual(PropertySetup."Tenant Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Nombre';
        }
        field(3; "ID No."; Text[20])
        {
            Caption = 'DNI/NIE';
        }
        field(4; Address; Text[100])
        {
            Caption = 'Dirección';
        }
        field(5; City; Text[50])
        {
            Caption = 'Población';
        }
        field(6; "Post Code"; Code[20])
        {
            Caption = 'Código postal';
        }
        field(7; "Phone No."; Text[30])
        {
            Caption = 'Nº teléfono';
            ExtendedDatatype = PhoneNo;
        }
        field(8; "E-Mail"; Text[80])
        {
            Caption = 'Correo electrónico';
            ExtendedDatatype = EMail;
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Nº cliente';
            TableRelation = Customer;
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'Nos. serie';
            TableRelation = "No. Series";
            Editable = false;
        }
        field(11; "Customer Type"; Code[20])
        {
            Caption = 'Tipo de cliente';
            TableRelation = "BeDyn Customer Type";
            ToolTip = 'Tipo de cliente del inquilino (particular, colaborador…). Las reservas lo heredan al asignarles este inquilino.';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, "Phone No.")
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
            PropertySetup.TestField("Tenant Nos.");
            "No. Series" := PropertySetup."Tenant Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    procedure AssistEdit(OldTenant: Record "BeDyn Tenant"): Boolean
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PropertySetup.GetInstance();
        PropertySetup.TestField("Tenant Nos.");
        if NoSeries.LookupRelatedNoSeries(PropertySetup."Tenant Nos.", OldTenant."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    trigger OnDelete()
    var
        Reservation: Record "BeDyn Reservation";
    begin
        Reservation.SetRange("Tenant No.", "No.");
        if not Reservation.IsEmpty() then
            Error(HasReservationsErr, "No.");
    end;

    var
        HasReservationsErr: Label 'No se puede eliminar el inquilino %1 porque tiene reservas.', Comment = '%1 = Nº inquilino';
}
