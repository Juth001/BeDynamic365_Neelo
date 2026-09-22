namespace BeDynamic.PropertyManagement;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.NoSeries;

table 82507 "BeDyn Reservation"
{
    Caption = 'Reserva';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Reservation List";
    DrillDownPageId = "BeDyn Reservation List";

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
                    NoSeries.TestManual(PropertySetup."Reservation Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Property No."; Code[20])
        {
            Caption = 'Nº propiedad';
            TableRelation = "BeDyn Property";
            NotBlank = true;

            trigger OnValidate()
            var
                Property: Record "BeDyn Property";
            begin
                "Room No." := '';
                if Property.Get("Property No.") then
                    "Billing Moment" := Property."Billing Moment";
                UpdateContractNo();
                UpdateRentalAmount();
                // La reserva hereda las dimensiones predeterminadas de la propiedad
                // (entre ellas PROPIEDAD), y sobre ellas se vuelve a poner el canal.
                CreateDimFromDefaults();
            end;
        }
        field(3; "Room No."; Code[20])
        {
            Caption = 'Nº subpropiedad';
            TableRelation = "BeDyn Property Room"."Room No." where("Property No." = field("Property No."));

            trigger OnValidate()
            var
                Property: Record "BeDyn Property";
            begin
                if "Room No." <> '' then begin
                    TestField("Property No.");
                    Property.Get("Property No.");
                    Property.TestField("Rental Type", Property."Rental Type"::"By Room");
                end;
                ApplyRoomDefaultTimes();
                UpdateRentalAmount();
            end;
        }
        field(4; "Tenant No."; Code[20])
        {
            Caption = 'Nº inquilino';
            TableRelation = "BeDyn Tenant";

            trigger OnValidate()
            var
                Tenant: Record "BeDyn Tenant";
            begin
                // El tipo de cliente vive en la ficha del inquilino; la reserva lo hereda.
                "Customer Type" := '';
                if ("Tenant No." <> '') and Tenant.Get("Tenant No.") then
                    "Customer Type" := Tenant."Customer Type";
            end;
        }
        field(5; "Tenant Name"; Text[100])
        {
            Caption = 'Nombre inquilino';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Tenant".Name where("No." = field("Tenant No.")));
            Editable = false;
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Fecha inicio';

            trigger OnValidate()
            begin
                CheckDates();
                UpdateRentalAmount();
            end;
        }
        field(7; "End Date"; Date)
        {
            Caption = 'Fecha fin';

            trigger OnValidate()
            begin
                CheckDates();
                UpdateRentalAmount();
            end;
        }
        field(8; Status; Enum "BeDyn Prop. Reservation Status")
        {
            Caption = 'Estado';
            Editable = false;
        }
        field(10; "Rental Amount"; Decimal)
        {
            Caption = 'Importe alquiler';
            MinValue = 0;
        }
        field(11; "Services Amount"; Decimal)
        {
            Caption = 'Importe servicios';
            FieldClass = FlowField;
            CalcFormula = sum("BeDyn Reservation Service".Amount where("Reservation No." = field("No.")));
            Editable = false;
        }
        field(12; "Check-In Date/Time"; DateTime)
        {
            Caption = 'Fecha/hora check-in';
            Editable = false;
        }
        field(13; "Check-Out Date/Time"; DateTime)
        {
            Caption = 'Fecha/hora check-out';
            Editable = false;
        }
        field(14; "Property Name"; Text[100])
        {
            Caption = 'Nombre propiedad';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Property".Name where("No." = field("Property No.")));
            Editable = false;
        }
        field(15; "No. Series"; Code[20])
        {
            Caption = 'Nos. serie';
            TableRelation = "No. Series";
            Editable = false;
        }
        field(16; "Price Basis"; Enum "BeDyn Price Basis")
        {
            Caption = 'Base de precio';

            trigger OnValidate()
            begin
                UpdateRentalAmount();
            end;
        }
        field(17; "Check-In Time"; Time)
        {
            Caption = 'Hora check-in';
        }
        field(18; "Check-Out Time"; Time)
        {
            Caption = 'Hora check-out';
        }
        field(19; "Contract No."; Code[20])
        {
            Caption = 'Nº contrato';
            TableRelation = "BeDyn Property Contract"."No." where("Property No." = field("Property No."));

            trigger OnValidate()
            var
                PropertyContract: Record "BeDyn Property Contract";
            begin
                if "Contract No." = '' then
                    exit;
                TestField("Property No.");
                PropertyContract.Get("Contract No.");
                PropertyContract.TestField("Property No.", "Property No.");
            end;
        }
        field(20; "Billing Moment"; Enum "BeDyn Billing Moment")
        {
            Caption = 'Momento de facturación';
        }
        field(21; "Invoiced Until"; Date)
        {
            Caption = 'Facturado hasta';
            Editable = false;
        }

        // ---------------- ORIGEN EXTERNO (IMPORTACIÓN) ----------------
        field(30; "External Id"; Code[50])
        {
            Caption = 'Id externo';
            ToolTip = 'Identificador de la reserva en el sistema de origen. Es la clave con la que la importación reconoce una reserva ya cargada, y viene siempre informado.';
        }
        field(31; "External Code"; Code[20])
        {
            Caption = 'Cód. externo';
            ToolTip = 'Código de reserva del sistema de origen. No se repite entre reservas, pero puede venir vacío en las reservas gestionadas a mano.';
        }
        field(32; "Customer Type"; Code[20])
        {
            Caption = 'Tipo de cliente';
            TableRelation = "BeDyn Customer Type";
            Editable = false;
            ToolTip = 'Tipo de cliente heredado de la ficha del inquilino al asignarlo a la reserva.';
        }
        field(33; "Guest Type"; Code[20])
        {
            Caption = 'Tipo de huésped';
            TableRelation = "BeDyn Guest Type";
            ToolTip = 'Tipo de huésped de esta reserva concreta, independiente del tipo de cliente del inquilino.';
        }
        field(34; "Channel Code"; Code[20])
        {
            Caption = 'Cód. canal';
            ToolTip = 'Canal por el que ha entrado la reserva. Es un valor de la dimensión de canal configurada, y se lleva al conjunto de dimensiones de la reserva para poder analizarla por canal.';

            trigger OnValidate()
            begin
                if "Channel Code" <> '' then
                    CheckChannelValue("Channel Code");
                ApplyChannelDimension();
            end;

            trigger OnLookup()
            var
                DimValue: Record "Dimension Value";
                ChannelDimension: Code[20];
            begin
                ChannelDimension := ChannelDimensionCode();
                if ChannelDimension = '' then
                    exit;
                DimValue.SetRange("Dimension Code", ChannelDimension);
                if Page.RunModal(Page::"Dimension Values", DimValue) = Action::LookupOK then
                    Validate("Channel Code", DimValue.Code);
            end;
        }
        field(35; "Monthly Rent"; Decimal)
        {
            Caption = 'Renta mensual';
            MinValue = 0;
            ToolTip = 'Renta mensual que paga el inquilino, según el origen de la reserva.';
        }
        field(36; "External Remark"; Text[250])
        {
            Caption = 'Observaciones origen';
            ToolTip = 'Anotaciones que traía la reserva en el fichero de origen (incidencias de la pasarela de pago, reubicaciones, etc.).';
        }

        // ---------------- DIMENSIONES ----------------
        field(40; "Dimension Set ID"; Integer)
        {
            Caption = 'Id conjunto dimensiones';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(41; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Cód. dimensión global 1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(42; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Cód. dimensión global 2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Availability; "Property No.", "Room No.", "Start Date")
        {
        }
        key(Tenant; "Tenant No.")
        {
        }
        key(Contract; "Contract No.")
        {
        }
        key(ExternalId; "External Id")
        {
        }
        key(ExternalCode; "External Code")
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
            PropertySetup.TestField("Reservation Nos.");
            "No. Series" := PropertySetup."Reservation Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        ApplyRoomDefaultTimes();
        if "Dimension Set ID" = 0 then
            CreateDimFromDefaults();
    end;

    // Horas de check-in/check-out por defecto: las de la subpropiedad de la
    // reserva o, en reservas de propiedad completa, las de la subpropiedad master.
    local procedure ApplyRoomDefaultTimes()
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        PropertyRoom: Record "BeDyn Property Room";
        RoomNo: Code[20];
    begin
        if "Property No." = '' then
            exit;
        RoomNo := "Room No.";
        if RoomNo = '' then begin
            PropertySetup.GetInstance();
            RoomNo := PropertySetup."Master Room Code";
        end;
        if RoomNo = '' then
            exit;
        if not PropertyRoom.Get("Property No.", RoomNo) then
            exit;
        if "Check-In Time" = 0T then
            "Check-In Time" := PropertyRoom."Check-In Time";
        if "Check-Out Time" = 0T then
            "Check-Out Time" := PropertyRoom."Check-Out Time";
    end;

    procedure AssistEdit(OldReservation: Record "BeDyn Reservation"): Boolean
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PropertySetup.GetInstance();
        PropertySetup.TestField("Reservation Nos.");
        if NoSeries.LookupRelatedNoSeries(PropertySetup."Reservation Nos.", OldReservation."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    trigger OnDelete()
    var
        ReservationService: Record "BeDyn Reservation Service";
    begin
        if Status = Status::CheckedIn then
            Error(CannotDeleteErr, "No.");
        ReservationService.SetRange("Reservation No.", "No.");
        ReservationService.DeleteAll();
    end;

    procedure GetTotalAmount(): Decimal
    begin
        CalcFields("Services Amount");
        exit("Rental Amount" + "Services Amount");
    end;

    local procedure CheckDates()
    begin
        if ("Start Date" <> 0D) and ("End Date" <> 0D) and ("End Date" <= "Start Date") then
            Error(InvalidDatesErr);
    end;

    // Si la propiedad tiene un único contrato activo, se asigna automáticamente.
    local procedure UpdateContractNo()
    var
        PropertyContract: Record "BeDyn Property Contract";
    begin
        "Contract No." := '';
        if "Property No." = '' then
            exit;
        PropertyContract.SetRange("Property No.", "Property No.");
        PropertyContract.SetRange(Status, PropertyContract.Status::Active);
        if PropertyContract.Count() = 1 then begin
            PropertyContract.FindFirst();
            "Contract No." := PropertyContract."No.";
        end;
    end;

    local procedure UpdateRentalAmount()
    var
        PropertyPriceMgt: Codeunit "BeDyn Property Price Mgt.";
    begin
        if ("Property No." = '') or ("Start Date" = 0D) or ("End Date" = 0D) or ("End Date" <= "Start Date") then
            exit;
        "Rental Amount" := PropertyPriceMgt.CalcRentalAmount(Rec);
    end;

    // Noches de la reserva: los días que van del check-in al check-out.
    procedure Nights(): Integer
    begin
        if ("Start Date" = 0D) or ("End Date" = 0D) then
            exit(0);
        exit("End Date" - "Start Date");
    end;

    // ------------------------------------------------------------ Dimensiones

    // Reconstruye el conjunto de dimensiones desde las predeterminadas de la
    // propiedad y vuelve a aplicar el canal encima.
    procedure CreateDimFromDefaults()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"BeDyn Property", "Property No.");
        "Dimension Set ID" := DimMgt.GetRecDefaultDimID(Rec, CurrFieldNo, DefaultDimSource, '', "Global Dimension 1 Code", "Global Dimension 2 Code", 0, 0);
        ApplyChannelDimension();
    end;

    // Escribe el canal en el conjunto de dimensiones. El valor tiene que existir
    // ya en la dimensión: aquí no se crean valores de dimensión por la puerta de
    // atrás, que la importación es quien decide si darlos de alta.
    local procedure ApplyChannelDimension()
    var
        ChannelDimension: Code[20];
    begin
        ChannelDimension := ChannelDimensionCode();
        if ChannelDimension = '' then
            exit;
        "Dimension Set ID" := DimMgt.SetDimensionValue("Dimension Set ID", ChannelDimension, "Channel Code", false, false);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    local procedure CheckChannelValue(ChannelValue: Code[20])
    var
        DimValue: Record "Dimension Value";
        ChannelDimension: Code[20];
        NoChannelDimErr: Label 'No hay configurada una dimensión de canal en la configuración de gestión de propiedades.';
        UnknownChannelErr: Label '%1 no es un valor de la dimensión %2.', Comment = '%1 = canal, %2 = código de dimensión';
    begin
        ChannelDimension := ChannelDimensionCode();
        if ChannelDimension = '' then
            Error(NoChannelDimErr);
        if not DimValue.Get(ChannelDimension, ChannelValue) then
            Error(UnknownChannelErr, ChannelValue, ChannelDimension);
    end;

    procedure ChannelDimensionCode(): Code[20]
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
    begin
        if not PropertySetup.Get() then
            exit('');
        exit(PropertySetup."Channel Dimension Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if ("No." <> '') and not IsTemporary() then
            Modify();
    end;

    procedure ShowDimensions()
    var
        DimensionsLbl: Label '%1 %2', Comment = '%1 = título de la tabla, %2 = Nº reserva', Locked = true;
    begin
        "Dimension Set ID" := DimMgt.EditDimensionSet(Rec, "Dimension Set ID", StrSubstNo(DimensionsLbl, TableCaption(), "No."), "Global Dimension 1 Code", "Global Dimension 2 Code");
        if ("No." <> '') and not IsTemporary() then
            Modify();
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        InvalidDatesErr: Label 'La fecha de fin debe ser posterior a la fecha de inicio.';
        CannotDeleteErr: Label 'No se puede eliminar la reserva %1 porque tiene el check-in realizado.', Comment = '%1 = Nº reserva';
}
