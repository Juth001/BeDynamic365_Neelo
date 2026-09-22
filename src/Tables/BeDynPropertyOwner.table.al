namespace BeDynamic.PropertyManagement;

using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 82501 "BeDyn Property Owner"
{
    Caption = 'Propietario';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Property Owner List";
    DrillDownPageId = "BeDyn Property Owner List";

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
                    NoSeries.TestManual(PropertySetup."Owner Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Nombre';
        }
        field(3; Address; Text[100])
        {
            Caption = 'Dirección';
        }
        field(4; City; Text[50])
        {
            Caption = 'Población';
        }
        field(5; "Post Code"; Code[20])
        {
            Caption = 'Código postal';
        }
        field(6; "Phone No."; Text[30])
        {
            Caption = 'Nº teléfono';
            ExtendedDatatype = PhoneNo;
        }
        field(7; "E-Mail"; Text[80])
        {
            Caption = 'Correo electrónico';
            ExtendedDatatype = EMail;
        }
        field(8; "Vendor No."; Code[20])
        {
            Caption = 'Nº proveedor';
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                if ("Vendor No." = '') and (xRec."Vendor No." <> '') then
                    CheckNoOpenVendorContracts();
            end;
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Nº cliente';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if ("Customer No." = '') and (xRec."Customer No." <> '') then
                    CheckNoOpenCustomerContracts();
            end;
        }
        field(10; "No. of Properties"; Integer)
        {
            Caption = 'Nº de propiedades';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Property" where("Owner No." = field("No.")));
            Editable = false;
        }
        field(11; "No. Series"; Code[20])
        {
            Caption = 'Nos. serie';
            TableRelation = "No. Series";
            Editable = false;
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
        fieldgroup(DropDown; "No.", Name, City)
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
            PropertySetup.TestField("Owner Nos.");
            "No. Series" := PropertySetup."Owner Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    procedure AssistEdit(OldPropertyOwner: Record "BeDyn Property Owner"): Boolean
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PropertySetup.GetInstance();
        PropertySetup.TestField("Owner Nos.");
        if NoSeries.LookupRelatedNoSeries(PropertySetup."Owner Nos.", OldPropertyOwner."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    trigger OnDelete()
    var
        Property: Record "BeDyn Property";
    begin
        Property.SetRange("Owner No.", "No.");
        if not Property.IsEmpty() then
            Error(HasPropertiesErr, "No.");
    end;

    // Los contratos de explotación en borrador o activos exigen que el propietario tenga proveedor.
    local procedure CheckNoOpenVendorContracts()
    var
        PropertyContract: Record "BeDyn Property Contract";
    begin
        PropertyContract.SetRange("Owner No.", "No.");
        PropertyContract.SetRange("Contract Type", PropertyContract."Contract Type"::Exploitation);
        PropertyContract.SetFilter(Status, '<>%1', PropertyContract.Status::Closed);
        if not PropertyContract.IsEmpty() then
            Error(CannotClearVendorErr, "No.");
    end;

    // Los contratos de gestión en borrador o activos exigen que el propietario tenga cliente.
    local procedure CheckNoOpenCustomerContracts()
    var
        PropertyContract: Record "BeDyn Property Contract";
    begin
        PropertyContract.SetRange("Owner No.", "No.");
        PropertyContract.SetRange("Contract Type", PropertyContract."Contract Type"::Management);
        PropertyContract.SetFilter(Status, '<>%1', PropertyContract.Status::Closed);
        if not PropertyContract.IsEmpty() then
            Error(CannotClearCustomerErr, "No.");
    end;

    var
        HasPropertiesErr: Label 'No se puede eliminar el propietario %1 porque tiene propiedades asociadas.', Comment = '%1 = Nº propietario';
        CannotClearVendorErr: Label 'No se puede quitar el proveedor del propietario %1 porque tiene contratos de explotación en borrador o activos.', Comment = '%1 = Nº propietario';
        CannotClearCustomerErr: Label 'No se puede quitar el cliente del propietario %1 porque tiene contratos de gestión en borrador o activos.', Comment = '%1 = Nº propietario';
}
