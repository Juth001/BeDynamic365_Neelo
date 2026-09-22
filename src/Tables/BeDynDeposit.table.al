namespace BeDynamic.PropertyManagement;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;

table 82512 "BeDyn Deposit"
{
    Caption = 'Fianza';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Deposit List";
    DrillDownPageId = "BeDyn Deposit List";

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
                    NoSeries.TestManual(PropertySetup."Deposit Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Reservation No."; Code[20])
        {
            Caption = 'Nº reserva';
            TableRelation = "BeDyn Reservation";
            NotBlank = true;

            trigger OnValidate()
            var
                Reservation: Record "BeDyn Reservation";
            begin
                if "Reservation No." = '' then
                    exit;
                Reservation.Get("Reservation No.");
                "Property No." := Reservation."Property No.";
                "Room No." := Reservation."Room No.";
                "Tenant No." := Reservation."Tenant No.";
            end;
        }
        field(3; "Property No."; Code[20])
        {
            Caption = 'Nº propiedad';
            TableRelation = "BeDyn Property";
            Editable = false;
        }
        field(4; "Room No."; Code[20])
        {
            Caption = 'Nº subpropiedad';
            TableRelation = "BeDyn Property Room"."Room No." where("Property No." = field("Property No."));
            Editable = false;
        }
        field(5; "Tenant No."; Code[20])
        {
            Caption = 'Nº inquilino';
            TableRelation = "BeDyn Tenant";
            Editable = false;
        }
        field(6; "Tenant Name"; Text[100])
        {
            Caption = 'Nombre inquilino';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Tenant".Name where("No." = field("Tenant No.")));
            Editable = false;
        }
        field(7; Months; Integer)
        {
            Caption = 'Meses de fianza';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField(Status, Status::Pending);
            end;
        }
        field(8; Amount; Decimal)
        {
            Caption = 'Importe';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField(Status, Status::Pending);
            end;
        }
        field(9; Status; Enum "BeDyn Deposit Status")
        {
            Caption = 'Estado';
            Editable = false;
        }
        field(10; "Collection Date"; Date)
        {
            Caption = 'Fecha cobro';
            Editable = false;
        }
        field(11; "Return Date"; Date)
        {
            Caption = 'Fecha devolución';
            Editable = false;
        }
        field(12; "Retained Amount"; Decimal)
        {
            Caption = 'Importe retenido';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Retained Amount" > Amount then
                    Error(RetainedTooHighErr);
                if Status in [Status::Returned, Status::Retained] then
                    Error(AlreadyReturnedErr, "No.");
            end;
        }
        field(13; "Document No."; Code[20])
        {
            Caption = 'Nº documento cobro';
            Editable = false;
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'Nos. serie';
            TableRelation = "No. Series";
            Editable = false;
        }
        field(15; "Property Name"; Text[100])
        {
            Caption = 'Nombre propiedad';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Property".Name where("No." = field("Property No.")));
            Editable = false;
        }
        field(20; "Returned Amount"; Decimal)
        {
            Caption = 'Importe devuelto';
            MinValue = 0;
            ToolTip = 'Importe de la fianza que ya se ha devuelto al inquilino. Lo que queda por devolver es el saldo: fianza menos devuelto menos retenido.';
        }
        field(21; "Posting Document No."; Code[20])
        {
            Caption = 'Nº documento contable';
            Editable = false;
            ToolTip = 'Nº de documento con el que se ha registrado el asiento de la fianza. Es el nº de la reserva, y con él se navega a los movimientos contables.';
        }
        field(22; "Posting Date"; Date)
        {
            Caption = 'Fecha registro contable';
            Editable = false;
            ToolTip = 'Fecha con la que se ha registrado el asiento de la fianza.';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Reservation; "Reservation No.")
        {
        }
        key(Tenant; "Tenant No.")
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
            PropertySetup.TestField("Deposit Nos.");
            "No. Series" := PropertySetup."Deposit Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnDelete()
    begin
        if Status <> Status::Pending then
            Error(CannotDeleteErr, "No.");
    end;

    procedure AssistEdit(OldDeposit: Record "BeDyn Deposit"): Boolean
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PropertySetup.GetInstance();
        PropertySetup.TestField("Deposit Nos.");
        if NoSeries.LookupRelatedNoSeries(PropertySetup."Deposit Nos.", OldDeposit."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    // Marca la fianza como cobrada. Se usa desde las páginas cuando el cobro se hace
    // aparte (sin factura); cuando va en la primera factura, el estado se actualiza al registrarla.
    procedure MarkCollected()
    begin
        TestField(Status, Status::Pending);
        TestField(Amount);
        Status := Status::Collected;
        "Collection Date" := WorkDate();
        Modify(true);
    end;

    // Registra la devolución. Si hay importe retenido queda como Retenida; si no, Devuelta.
    procedure MarkReturned()
    begin
        TestField(Status, Status::Collected);
        if "Retained Amount" > Amount then
            Error(RetainedTooHighErr);
        if "Retained Amount" > 0 then
            Status := Status::Retained
        else
            Status := Status::Returned;
        "Return Date" := WorkDate();
        Modify(true);
    end;

    // Lo que queda por devolver al inquilino de la fianza que entregó.
    procedure Balance(): Decimal
    begin
        exit(Amount - "Returned Amount" - "Retained Amount");
    end;

    procedure IsPosted(): Boolean
    begin
        exit("Posting Document No." <> '');
    end;

    // Movimientos contables del asiento de la fianza: el cargo en la cuenta
    // puente y el abono en la de fianzas comparten documento y fecha.
    procedure ShowLedgerEntries()
    var
        GLEntry: Record "G/L Entry";
        NotPostedErr: Label 'La fianza %1 todavía no tiene asiento contable.', Comment = '%1 = Nº fianza';
    begin
        if not IsPosted() then
            Error(NotPostedErr, "No.");
        GLEntry.SetRange("Document No.", "Posting Document No.");
        if "Posting Date" <> 0D then
            GLEntry.SetRange("Posting Date", "Posting Date");
        Page.Run(Page::"General Ledger Entries", GLEntry);
    end;

    procedure NavigateDocument()
    var
        Navigate: Page Navigate;
        NotPostedErr: Label 'La fianza %1 todavía no tiene asiento contable.', Comment = '%1 = Nº fianza';
    begin
        if not IsPosted() then
            Error(NotPostedErr, "No.");
        Navigate.SetDoc("Posting Date", "Posting Document No.");
        Navigate.Run();
    end;

    var
        RetainedTooHighErr: Label 'El importe retenido no puede superar el importe de la fianza.';
        AlreadyReturnedErr: Label 'La fianza %1 ya está devuelta o retenida.', Comment = '%1 = Nº fianza';
        CannotDeleteErr: Label 'No se puede eliminar la fianza %1 porque no está pendiente.', Comment = '%1 = Nº fianza';
}
