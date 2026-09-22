namespace BeDynamic.PropertyManagement;

using Microsoft.eServices.OnlineMap;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;

table 82502 "BeDyn Property"
{
    Caption = 'Propiedad';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Property List";
    DrillDownPageId = "BeDyn Property List";

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
                    NoSeries.TestManual(PropertySetup."Property Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Nombre';
        }
        field(3; "Owner No."; Code[20])
        {
            Caption = 'Nº propietario';
            TableRelation = "BeDyn Property Owner";
            NotBlank = true;
        }
        field(4; "Owner Name"; Text[100])
        {
            Caption = 'Nombre propietario';
            FieldClass = FlowField;
            CalcFormula = lookup("BeDyn Property Owner".Name where("No." = field("Owner No.")));
            Editable = false;
        }
        field(5; "Rental Type"; Enum "BeDyn Property Rental Type")
        {
            Caption = 'Tipo de alquiler';

            trigger OnValidate()
            var
                Reservation: Record "BeDyn Reservation";
            begin
                if "Rental Type" = xRec."Rental Type" then
                    exit;
                Reservation.SetRange("Property No.", "No.");
                Reservation.SetFilter(Status, '<>%1', Reservation.Status::Cancelled);
                if not Reservation.IsEmpty() then
                    Error(RentalTypeChangeErr, "No.");
            end;
        }
        field(6; Address; Text[100])
        {
            Caption = 'Dirección';
        }
        field(7; City; Text[30])
        {
            Caption = 'Población';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                LookupCityAndCounty();
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; "Post Code"; Code[20])
        {
            Caption = 'Código postal';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                LookupCityAndCounty();
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Address 2"; Text[50])
        {
            Caption = 'Dirección 2';
        }
        field(10; "No. of Rooms"; Integer)
        {
            Caption = 'Nº de subpropiedades';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Property Room" where("Property No." = field("No."), "Master Room" = const(false)));
            Editable = false;
        }
        field(11; "No. Series"; Code[20])
        {
            Caption = 'Nos. serie';
            TableRelation = "No. Series";
            Editable = false;
        }
        field(12; "Status Code"; Code[20])
        {
            Caption = 'Cód. estado';
            TableRelation = "BeDyn Property Status";
        }
        field(16; "External Id"; Code[50])
        {
            Caption = 'Id externo';
        }
        field(18; Picture; MediaSet)
        {
            Caption = 'Imagen';
        }
        field(19; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'Provincia';
        }
        field(20; "Country/Region Code"; Code[10])
        {
            Caption = 'Cód. país/región';
            TableRelation = "Country/Region";

            trigger OnValidate()
            var
                CityText: Text;
                CountyText: Text;
            begin
                // Variables intermedias: el método escribe en parámetros Text sin límite.
                CityText := City;
                CountyText := County;
                PostCode.CheckClearPostCodeCityCounty(CityText, "Post Code", CountyText, "Country/Region Code", xRec."Country/Region Code");
                City := CopyStr(CityText, 1, MaxStrLen(City));
                County := CopyStr(CountyText, 1, MaxStrLen(County));
            end;
        }
        field(21; "Item No."; Code[20])
        {
            Caption = 'Nº producto';
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
                PropertyRoom: Record "BeDyn Property Room";
            begin
                if "Item No." = xRec."Item No." then
                    exit;
                PropertyRoom.SetRange("Property No.", "No.");
                PropertyRoom.SetFilter("Variant Code", '<>%1', '');
                if not PropertyRoom.IsEmpty() then
                    Error(ItemNoChangeErr, "No.");

                if "Item No." <> '' then begin
                    Item.Get("Item No.");
                    Picture := Item.Picture;
                end;
            end;
        }
        field(24; Capacity; Integer)
        {
            Caption = 'Capacidad';
            FieldClass = FlowField;
            CalcFormula = sum("BeDyn Property Room".Capacity where("Property No." = field("No."), "Master Room" = const(false)));
            Editable = false;
        }
        field(27; "No. of Bathrooms"; Integer)
        {
            Caption = 'Nº de baños';
            MinValue = 0;
        }
        field(28; "Billing Moment"; Enum "BeDyn Billing Moment")
        {
            Caption = 'Momento de facturación';
        }
        field(29; "Deposit Months"; Integer)
        {
            Caption = 'Meses de fianza';
            MinValue = 0;
        }
        field(30; "Job No."; Code[20])
        {
            Caption = 'Nº proyecto';
            TableRelation = Job;
        }
        field(31; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Cód. dimensión global 1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(32; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Cód. dimensión global 2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(33; "Cadastral Reference"; Code[20])
        {
            Caption = 'Referencia catastral';
        }
        field(34; "Property Type Code"; Code[20])
        {
            Caption = 'Cód. tipo propiedad';
            TableRelation = "BeDyn Property Type";

            trigger OnValidate()
            var
                PropertyRoom: Record "BeDyn Property Room";
                RoomType: Record "BeDyn Room Type";
                RoomTypeMismatchErr: Label 'La subpropiedad %1 tiene el tipo de subpropiedad %2, que pertenece al tipo de propiedad %3. Cambia primero el tipo de las subpropiedades.', Comment = '%1 = subpropiedad, %2 = tipo subpropiedad, %3 = tipo propiedad';
            begin
                if "Property Type Code" = xRec."Property Type Code" then
                    exit;
                // Los tipos de subpropiedad ya asignados deben ser compatibles con
                // el nuevo tipo de propiedad.
                PropertyRoom.SetRange("Property No.", "No.");
                PropertyRoom.SetFilter("Room Type Code", '<>%1', '');
                if PropertyRoom.FindSet() then
                    repeat
                        if RoomType.Get(PropertyRoom."Room Type Code") then
                            if (RoomType."Property Type Code" <> '') and (RoomType."Property Type Code" <> "Property Type Code") then
                                Error(RoomTypeMismatchErr, PropertyRoom."Room No.", RoomType.Code, RoomType."Property Type Code");
                    until PropertyRoom.Next() = 0;
            end;
        }
        field(35; "Virtual Tour URL"; Text[250])
        {
            Caption = 'URL tour virtual';
            ExtendedDatatype = URL;
        }
        field(36; "Marketing Text"; Blob)
        {
            Caption = 'Texto de marketing';
        }
        field(37; "House Rules Text"; Blob)
        {
            Caption = 'Normas de la casa';
        }
        field(38; "Transit Text"; Blob)
        {
            Caption = 'Cómo llegar (transit)';
        }
        field(39; "Access Text"; Blob)
        {
            Caption = 'Acceso (access)';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Owner; "Owner No.")
        {
        }
        key(ExternalId; "External Id")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, City, "Rental Type")
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
            PropertySetup.TestField("Property Nos.");
            "No. Series" := PropertySetup."Property Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        PropertySetup.GetInstance();
        "Billing Moment" := PropertySetup."Def. Billing Moment";

        CreateMasterRoom();
    end;

    local procedure CreateMasterRoom()
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        PropertyRoom: Record "BeDyn Property Room";
    begin
        PropertySetup.GetInstance();
        if PropertySetup."Master Room Code" = '' then
            exit;
        if PropertyRoom.Get("No.", PropertySetup."Master Room Code") then
            exit;
        PropertyRoom.Init();
        PropertyRoom."Property No." := "No.";
        PropertyRoom."Room No." := PropertySetup."Master Room Code";
        PropertyRoom.Description := MasterRoomDescriptionTxt;
        PropertyRoom.Insert(true);
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::"BeDyn Property", CopyStr(GetPosition(), 1, 1000));
    end;

    // Lookup compartido de población/provincia: el método estándar escribe en
    // parámetros Text sin límite, de ahí las variables intermedias.
    local procedure LookupCityAndCounty()
    var
        CityText: Text;
        CountyText: Text;
    begin
        CityText := City;
        CountyText := County;
        PostCode.LookupPostCode(CityText, "Post Code", CountyText, "Country/Region Code");
        City := CopyStr(CityText, 1, MaxStrLen(City));
        County := CopyStr(CountyText, 1, MaxStrLen(County));
    end;

    procedure AssistEdit(OldProperty: Record "BeDyn Property"): Boolean
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PropertySetup.GetInstance();
        PropertySetup.TestField("Property Nos.");
        if NoSeries.LookupRelatedNoSeries(PropertySetup."Property Nos.", OldProperty."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    trigger OnDelete()
    var
        PropertyAmenity: Record "BeDyn Property Amenity";
        PropertyImage: Record "BeDyn Property Image";
        PropertyRoom: Record "BeDyn Property Room";
        PropertyContract: Record "BeDyn Property Contract";
        PropertyPortalLink: Record "BeDyn Property Portal Link";
        PropertyTextTranslation: Record "BeDyn Prop. Text Translation";
        Reservation: Record "BeDyn Reservation";
    begin
        Reservation.SetRange("Property No.", "No.");
        if not Reservation.IsEmpty() then
            Error(HasReservationsErr, "No.");

        PropertyContract.SetRange("Property No.", "No.");
        if not PropertyContract.IsEmpty() then
            Error(HasContractsErr, "No.");

        PropertyRoom.SetRange("Property No.", "No.");
        PropertyRoom.DeleteAll(true);

        PropertyPortalLink.SetRange("Property No.", "No.");
        PropertyPortalLink.DeleteAll();

        PropertyAmenity.SetRange("Property No.", "No.");
        PropertyAmenity.DeleteAll();

        PropertyImage.SetRange("Property No.", "No.");
        PropertyImage.DeleteAll();

        PropertyTextTranslation.SetRange("Property No.", "No.");
        PropertyTextTranslation.SetRange("Room No.", '');
        PropertyTextTranslation.DeleteAll();

        DimMgt.DeleteDefaultDim(Database::"BeDyn Property", "No.");
    end;

    // ==================== TEXTOS (idioma por defecto) ====================
    // El texto en el idioma por defecto vive en el blob del registro; las
    // traducciones, en la tabla "Property Text Translation".

    procedure GetText(TextType: Enum "BeDyn Property Text Type"): Text
    var
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


    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(Database::"BeDyn Property", xRec."No.", "No.");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary() then begin
            DimMgt.SaveDefaultDim(Database::"BeDyn Property", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    var
        PostCode: Record "Post Code";
        DimMgt: Codeunit DimensionManagement;
        PropertyTextMgt: Codeunit "BeDyn Property Text Mgt.";
        HasReservationsErr: Label 'No se puede eliminar la propiedad %1 porque tiene reservas.', Comment = '%1 = Nº propiedad';
        HasContractsErr: Label 'No se puede eliminar la propiedad %1 porque tiene contratos.', Comment = '%1 = Nº propiedad';
        RentalTypeChangeErr: Label 'No se puede cambiar el tipo de alquiler de la propiedad %1 porque tiene reservas activas.', Comment = '%1 = Nº propiedad';
        ItemNoChangeErr: Label 'No se puede cambiar el producto de la propiedad %1 porque tiene subpropiedades con variante asignada.', Comment = '%1 = Nº propiedad';
        MasterRoomDescriptionTxt: Label 'Subpropiedad master';
}
