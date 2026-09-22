namespace BeDynamic.PropertyManagement;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;

table 82503 "BeDyn Property Room"
{
    Caption = 'Subpropiedad';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Property No."; Code[20])
        {
            Caption = 'Nº propiedad';
            TableRelation = "BeDyn Property";
            NotBlank = true;
        }
        field(2; "Room No."; Code[20])
        {
            Caption = 'Nº subpropiedad';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Descripción';
        }
        field(4; Capacity; Integer)
        {
            Caption = 'Capacidad';
            MinValue = 0;
        }
        field(5; "External Id"; Code[50])
        {
            Caption = 'Id externo';
        }
        field(6; Picture; MediaSet)
        {
            Caption = 'Imagen';
        }
        field(7; "Variant Code"; Code[10])
        {
            Caption = 'Cód. variante';
            TableRelation = "Item Variant".Code;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                ItemVariant: Record "Item Variant";
                ItemNo: Code[20];
            begin
                ItemNo := GetPropertyItemNo();
                ItemVariant.FilterGroup(2);
                ItemVariant.SetRange("Item No.", ItemNo);
                ItemVariant.SetRange(Blocked, false);
                ItemVariant.FilterGroup(0);
                if ItemVariant.Get(ItemNo, "Variant Code") then;
                if Page.RunModal(0, ItemVariant) = Action::LookupOK then
                    Validate("Variant Code", ItemVariant.Code);
            end;

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" = '' then
                    exit;
                ItemVariant.Get(GetPropertyItemNo(), "Variant Code");
                ItemVariant.TestField(Blocked, false);
                Picture := ItemVariant.Picture;
            end;
        }
        field(9; "Room Type Code"; Code[20])
        {
            Caption = 'Cód. tipo subpropiedad';
            TableRelation = "BeDyn Room Type";
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                RoomType: Record "BeDyn Room Type";
                PropertyTypeCode: Code[20];
            begin
                // Solo tipos de subpropiedad del tipo de la propiedad madre (o
                // genéricos, sin tipo de propiedad).
                PropertyTypeCode := GetPropertyTypeCode();
                RoomType.FilterGroup(2);
                if PropertyTypeCode <> '' then
                    RoomType.SetFilter("Property Type Code", '%1|%2', '', PropertyTypeCode)
                else
                    RoomType.SetRange("Property Type Code", '');
                RoomType.FilterGroup(0);
                if RoomType.Get("Room Type Code") then;
                if Page.RunModal(0, RoomType) = Action::LookupOK then
                    Validate("Room Type Code", RoomType.Code);
            end;

            trigger OnValidate()
            var
                RoomType: Record "BeDyn Room Type";
                WrongPropertyTypeErr: Label 'El tipo de subpropiedad %1 pertenece al tipo de propiedad %2, pero la propiedad %3 es de tipo %4.', Comment = '%1 = tipo subpropiedad, %2 = su tipo propiedad, %3 = propiedad, %4 = tipo de la propiedad';
            begin
                if "Room Type Code" = '' then
                    exit;
                RoomType.Get("Room Type Code");
                if (RoomType."Property Type Code" <> '') and (RoomType."Property Type Code" <> GetPropertyTypeCode()) then
                    Error(WrongPropertyTypeErr, RoomType.Code, RoomType."Property Type Code", "Property No.", GetPropertyTypeCode());
            end;
        }
        field(10; "Square Meters"; Decimal)
        {
            Caption = 'Metros cuadrados';
            MinValue = 0;
            DecimalPlaces = 0 : 2;
        }
        field(17; "Master Room"; Boolean)
        {
            Caption = 'Subpropiedad master';
            Editable = false;
        }
        field(18; "Marketing Text"; Blob)
        {
            Caption = 'Texto de marketing';
        }
        field(19; "No. of Reservations"; Integer)
        {
            Caption = 'Nº de reservas';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Reservation" where("Property No." = field("Property No."), "Room No." = field("Room No.")));
            Editable = false;
        }
        field(20; "Drive Folder URL"; Text[250])
        {
            Caption = 'URL carpeta Drive';
            ExtendedDatatype = URL;
        }
        field(21; "Job Task No."; Code[20])
        {
            Caption = 'Nº tarea proyecto';
            TableRelation = "Job Task"."Job Task No.";
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                JobTask: Record "Job Task";
                JobNo: Code[20];
            begin
                JobNo := GetPropertyJobNo();
                JobTask.FilterGroup(2);
                JobTask.SetRange("Job No.", JobNo);
                JobTask.FilterGroup(0);
                if JobTask.Get(JobNo, "Job Task No.") then;
                if Page.RunModal(0, JobTask) = Action::LookupOK then
                    Validate("Job Task No.", JobTask."Job Task No.");
            end;

            trigger OnValidate()
            var
                JobTask: Record "Job Task";
            begin
                if "Job Task No." = '' then
                    exit;
                JobTask.Get(GetPropertyJobNo(), "Job Task No.");
            end;
        }
        field(22; "Check-In Time"; Time)
        {
            Caption = 'Hora check-in';
            ToolTip = 'Hora de check-in de la subpropiedad. Se propone por defecto en sus nuevas reservas.';
        }
        field(23; "Check-Out Time"; Time)
        {
            Caption = 'Hora check-out';
            ToolTip = 'Hora de check-out de la subpropiedad. Se propone por defecto en sus nuevas reservas.';
        }
        field(24; "House Rules Text"; Blob)
        {
            Caption = 'Normas de la casa';
        }
        field(25; "Transit Text"; Blob)
        {
            Caption = 'Cómo llegar (transit)';
        }
        field(26; "Access Text"; Blob)
        {
            Caption = 'Acceso (access)';
        }
    }

    keys
    {
        key(PK; "Property No.", "Room No.")
        {
            Clustered = true;
            SumIndexFields = Capacity;
        }
        key(ExternalId; "External Id")
        {
        }
        // SIFT para el flowfield Capacity de la propiedad (filtra por Master Room).
        key(PropertyMaster; "Property No.", "Master Room")
        {
            SumIndexFields = Capacity;
        }
    }

    trigger OnInsert()
    begin
        UpdateMasterRoom();
    end;

    trigger OnRename()
    begin
        UpdateMasterRoom();
    end;

    trigger OnDelete()
    var
        PropertyAmenity: Record "BeDyn Property Amenity";
        PropertyImage: Record "BeDyn Property Image";
        PropertyTextTranslation: Record "BeDyn Prop. Text Translation";
        Reservation: Record "BeDyn Reservation";
    begin
        Reservation.SetRange("Property No.", "Property No.");
        Reservation.SetRange("Room No.", "Room No.");
        Reservation.SetFilter(Status, '<>%1', Reservation.Status::Cancelled);
        if not Reservation.IsEmpty() then
            Error(HasReservationsErr, "Room No.", "Property No.");

        PropertyAmenity.SetRange("Property No.", "Property No.");
        PropertyAmenity.SetRange("Room No.", "Room No.");
        PropertyAmenity.DeleteAll();

        PropertyImage.SetRange("Property No.", "Property No.");
        PropertyImage.SetRange("Room No.", "Room No.");
        PropertyImage.DeleteAll();

        PropertyTextTranslation.SetRange("Property No.", "Property No.");
        PropertyTextTranslation.SetRange("Room No.", "Room No.");
        PropertyTextTranslation.DeleteAll();
    end;

    // ==================== TEXTOS (idioma por defecto) ====================
    // El texto en el idioma por defecto vive en el blob del registro; las
    // traducciones, en la tabla "Property Text Translation".

    procedure GetText(TextType: Enum "BeDyn Property Text Type"): Text
    var
        PropertyTextMgt: Codeunit "BeDyn Property Text Mgt.";
        InStr: InStream;
    begin
        CalcFields("Marketing Text", "House Rules Text", "Transit Text", "Access Text");
        case TextType of
            TextType::Marketing:
                begin
                    if not "Marketing Text".HasValue() then
                        exit('');
                    "Marketing Text".CreateInStream(InStr, TextEncoding::UTF8);
                end;
            TextType::"House Rules":
                begin
                    if not "House Rules Text".HasValue() then
                        exit('');
                    "House Rules Text".CreateInStream(InStr, TextEncoding::UTF8);
                end;
            TextType::Transit:
                begin
                    if not "Transit Text".HasValue() then
                        exit('');
                    "Transit Text".CreateInStream(InStr, TextEncoding::UTF8);
                end;
            TextType::Access:
                begin
                    if not "Access Text".HasValue() then
                        exit('');
                    "Access Text".CreateInStream(InStr, TextEncoding::UTF8);
                end;
        end;
        exit(PropertyTextMgt.ReadAllText(InStr));
    end;

    procedure SetText(TextType: Enum "BeDyn Property Text Type"; NewContent: Text)
    var
        OutStr: OutStream;
    begin
        case TextType of
            TextType::Marketing:
                Clear("Marketing Text");
            TextType::"House Rules":
                Clear("House Rules Text");
            TextType::Transit:
                Clear("Transit Text");
            TextType::Access:
                Clear("Access Text");
        end;
        if NewContent <> '' then begin
            case TextType of
                TextType::Marketing:
                    "Marketing Text".CreateOutStream(OutStr, TextEncoding::UTF8);
                TextType::"House Rules":
                    "House Rules Text".CreateOutStream(OutStr, TextEncoding::UTF8);
                TextType::Transit:
                    "Transit Text".CreateOutStream(OutStr, TextEncoding::UTF8);
                TextType::Access:
                    "Access Text".CreateOutStream(OutStr, TextEncoding::UTF8);
            end;
            OutStr.WriteText(NewContent);
        end;
        Modify();
    end;

    procedure GetMarketingText(): Text
    begin
        exit(GetText("BeDyn Property Text Type"::Marketing));
    end;

    procedure SetMarketingText(NewMarketingText: Text)
    begin
        SetText("BeDyn Property Text Type"::Marketing, NewMarketingText);
    end;

    local procedure UpdateMasterRoom()
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
    begin
        PropertySetup.GetInstance();
        "Master Room" := (PropertySetup."Master Room Code" <> '') and ("Room No." = PropertySetup."Master Room Code");
    end;

    local procedure GetPropertyItemNo(): Code[20]
    var
        Property: Record "BeDyn Property";
    begin
        Property.Get("Property No.");
        Property.TestField("Item No.");
        exit(Property."Item No.");
    end;

    local procedure GetPropertyJobNo(): Code[20]
    var
        Property: Record "BeDyn Property";
    begin
        Property.Get("Property No.");
        Property.TestField("Job No.");
        exit(Property."Job No.");
    end;

    local procedure GetPropertyTypeCode(): Code[20]
    var
        Property: Record "BeDyn Property";
    begin
        if not Property.Get("Property No.") then
            exit('');
        exit(Property."Property Type Code");
    end;

    var
        HasReservationsErr: Label 'No se puede eliminar la subpropiedad %1 de la propiedad %2 porque tiene reservas activas.', Comment = '%1 = Nº subpropiedad, %2 = Nº propiedad';
}
