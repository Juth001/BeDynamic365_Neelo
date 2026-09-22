namespace BeDynamic.PropertyManagement;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item.Attribute;

page 82504 "BeDyn Property Card"
{
    PageType = Card;
    SourceTable = "BeDyn Property";
    Caption = 'Ficha propiedad';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de la propiedad.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de la propiedad.';
                }
                field("Owner No."; Rec."Owner No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propietario de la propiedad.';
                }
                field("Owner Name"; Rec."Owner Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del propietario.';
                }
                field("Rental Type"; Rec."Rental Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si se alquila la propiedad completa o por subpropiedades.';
                }
                field("Property Type Code"; Rec."Property Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tipo de propiedad (p. ej. APARTAMENTO, CASA, LOFT). Determina qué tipos de subpropiedad se pueden asignar a sus subpropiedades.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado de la propiedad (p. ej. ACTIVO, PUBLICADO, BAJA).';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Producto asociado a la propiedad. Las variantes de este producto se pueden asignar a las subpropiedades.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Proyecto asociado a la propiedad.';
                }
                field("No. of Rooms"; Rec."No. of Rooms")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de subpropiedades registradas.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Capacidad total en personas, calculada como la suma de las capacidades de las subpropiedades, sin incluir la subpropiedad master.';
                }
                field("No. of Bathrooms"; Rec."No. of Bathrooms")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de baños de la propiedad.';
                }
                field("External Id"; Rec."External Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identificador de la propiedad en un sistema externo.';
                }
                field("Virtual Tour URL"; Rec."Virtual Tour URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enlace al tour virtual de la propiedad.';
                }
            }
            group(Billing)
            {
                Caption = 'Facturación';

                field("Billing Moment"; Rec."Billing Moment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Momento en que se facturan las reservas por noche de esta propiedad: al check-in (prepago) o al check-out. Se propone en las nuevas reservas.';
                }
                field("Deposit Months"; Rec."Deposit Months")
                {
                    ApplicationArea = All;
                    ToolTip = 'Meses de alquiler que se cobran como fianza al confirmar una reserva mensual. Con cero no se genera fianza.';
                }
            }
            group(AddressGroup)
            {
                Caption = 'Dirección';

                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    ToolTip = 'Dirección de la propiedad.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Información adicional de la dirección.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'País o región de la dirección.';

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                    end;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Población de la propiedad.';
                }
                group(CountyGroup)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;

                    field(County; Rec.County)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Provincia o estado de la dirección.';
                    }
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código postal.';
                }
                field("Cadastral Reference"; Rec."Cadastral Reference")
                {
                    ApplicationArea = All;
                    ToolTip = 'Referencia catastral de la propiedad (20 caracteres).';
                }
                field(ShowMap; ShowMapLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Muestra la dirección de la propiedad en su servicio de mapas preferido.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.Update(true);
                        Rec.DisplayMap();
                    end;
                }
            }
            group(MarketingTextGroup)
            {
                Caption = 'Texto de marketing';

                field(MarketingText; MarketingTextValue)
                {
                    ApplicationArea = All;
                    Caption = 'Texto de marketing';
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Texto de marketing de la propiedad, con formato enriquecido, para usar en anuncios y portales. Las traducciones se gestionan con la acción Traducciones.';

                    trigger OnValidate()
                    begin
                        Rec.SetText("BeDyn Property Text Type"::Marketing, MarketingTextValue);
                    end;
                }
            }
            group(HouseRulesGroup)
            {
                Caption = 'Normas de la casa';

                field(HouseRulesText; HouseRulesValue)
                {
                    ApplicationArea = All;
                    Caption = 'Normas de la casa';
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Normas de la casa (house rules) de la propiedad, con formato enriquecido. Las traducciones se gestionan con la acción Traducciones.';

                    trigger OnValidate()
                    begin
                        Rec.SetText("BeDyn Property Text Type"::"House Rules", HouseRulesValue);
                    end;
                }
            }
            group(TransitGroup)
            {
                Caption = 'Cómo llegar (transit)';

                field(TransitText; TransitValue)
                {
                    ApplicationArea = All;
                    Caption = 'Cómo llegar (transit)';
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Indicaciones de transporte y cómo llegar (transit), con formato enriquecido. Las traducciones se gestionan con la acción Traducciones.';

                    trigger OnValidate()
                    begin
                        Rec.SetText("BeDyn Property Text Type"::Transit, TransitValue);
                    end;
                }
            }
            group(AccessGroup)
            {
                Caption = 'Acceso (access)';

                field(AccessText; AccessValue)
                {
                    ApplicationArea = All;
                    Caption = 'Acceso (access)';
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Instrucciones de acceso al alojamiento (access), con formato enriquecido. Las traducciones se gestionan con la acción Traducciones.';

                    trigger OnValidate()
                    begin
                        Rec.SetText("BeDyn Property Text Type"::Access, AccessValue);
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                ApplicationArea = All;
                Caption = 'Características';
            }
            part(GalleryFactbox; "BeDyn Property Image Gallery")
            {
                ApplicationArea = All;
                Caption = 'Galería';
                SubPageLink = "Property No." = field("No."), "Room No." = const('');
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Rooms)
            {
                ApplicationArea = All;
                Caption = 'Subpropiedades';
                Image = Home;
                RunObject = page "BeDyn Property Room List";
                RunPageLink = "Property No." = field("No.");
                ToolTip = 'Ver las subpropiedades de esta propiedad.';
            }
            action(Amenities)
            {
                ApplicationArea = All;
                Caption = 'Amenities';
                Image = ServiceItem;
                RunObject = page "BeDyn Property Amenity List";
                RunPageLink = "Property No." = field("No.");
                RunPageView = where(Location = const("Common Area"));
                ToolTip = 'Ver los amenities de las zonas comunes de esta propiedad. Los amenities de las subpropiedades se gestionan desde cada subpropiedad.';
            }
            action(Prices)
            {
                ApplicationArea = All;
                Caption = 'Precios';
                Image = Price;
                RunObject = page "BeDyn Property Item Prices";
                RunPageLink = "Item No." = field("Item No.");
                ToolTip = 'Ver los precios configurados en las listas de precios del producto vinculado a la propiedad.';
            }
            action(Portals)
            {
                ApplicationArea = All;
                Caption = 'Portales';
                Image = Web;
                RunObject = page "BeDyn Property Portal Links";
                RunPageLink = "Property No." = field("No.");
                ToolTip = 'Ver los portales donde está publicada esta propiedad.';
            }
            action(TextTranslations)
            {
                ApplicationArea = All;
                Caption = 'Traducciones';
                Image = Translations;
                ToolTip = 'Traducciones por idioma de los textos de la propiedad (marketing, normas de la casa, cómo llegar y acceso).';

                trigger OnAction()
                var
                    PropertyTextMgt: Codeunit "BeDyn Property Text Mgt.";
                begin
                    PropertyTextMgt.EditTranslations(Rec."No.", '');
                end;
            }
            action(Contracts)
            {
                ApplicationArea = All;
                Caption = 'Contratos';
                Image = Agreement;
                RunObject = page "BeDyn Property Contract List";
                RunPageLink = "Property No." = field("No.");
                ToolTip = 'Ver los contratos de esta propiedad.';
            }
            action(Reservations)
            {
                ApplicationArea = All;
                Caption = 'Reservas';
                Image = Reserve;
                RunObject = page "BeDyn Reservation List";
                RunPageLink = "Property No." = field("No.");
                ToolTip = 'Ver las reservas de esta propiedad.';
            }
            action(AvailabilityCalendar)
            {
                ApplicationArea = All;
                Caption = 'Calendario disponibilidad';
                Image = Calendar;
                RunObject = page "BeDyn Room Avail. Calendar";
                RunPageLink = "Property No." = field("No.");
                ToolTip = 'Ver la disponibilidad de las subpropiedades de esta propiedad en un calendario mensual.';
            }
            action(Deposits)
            {
                ApplicationArea = All;
                Caption = 'Fianzas';
                Image = Balance;
                RunObject = page "BeDyn Deposit List";
                RunPageLink = "Property No." = field("No.");
                ToolTip = 'Ver las fianzas de las reservas de esta propiedad.';
            }
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensiones';
                Image = Dimensions;
                ShortcutKey = 'Alt+D';
                RunObject = page "Default Dimensions";
                RunPageLink = "Table ID" = const(Database::"BeDyn Property"), "No." = field("No.");
                ToolTip = 'Ver o editar las dimensiones predeterminadas de esta propiedad.';
            }
        }
        area(Reporting)
        {
            action(AmenityInventory)
            {
                ApplicationArea = All;
                Caption = 'Inventario de amenities';
                Image = Report;
                ToolTip = 'Imprime el inventario de amenities de la propiedad, indicando si están en zonas comunes o en qué subpropiedad se encuentran.';

                trigger OnAction()
                var
                    Property: Record "BeDyn Property";
                    AmenityInventory: Report "BeDyn Prop. Amenity Inventory";
                begin
                    Property.SetRange("No.", Rec."No.");
                    AmenityInventory.SetTableView(Property);
                    AmenityInventory.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Rooms_Promoted; Rooms)
                {
                }
                actionref(Amenities_Promoted; Amenities)
                {
                }
                actionref(Prices_Promoted; Prices)
                {
                }
                actionref(Portals_Promoted; Portals)
                {
                }
                actionref(Contracts_Promoted; Contracts)
                {
                }
                actionref(Reservations_Promoted; Reservations)
                {
                }
                actionref(AvailabilityCalendar_Promoted; AvailabilityCalendar)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
            group(Category_Report)
            {
                actionref(AmenityInventory_Promoted; AmenityInventory)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        CurrPage.ItemAttributesFactbox.Page.LoadItemAttributesData(Rec."Item No.");
        MarketingTextValue := Rec.GetText("BeDyn Property Text Type"::Marketing);
        HouseRulesValue := Rec.GetText("BeDyn Property Text Type"::"House Rules");
        TransitValue := Rec.GetText("BeDyn Property Text Type"::Transit);
        AccessValue := Rec.GetText("BeDyn Property Text Type"::Access);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        // Heredar el propietario cuando la ficha se abre desde una lista
        // filtrada por propietario (p.ej. acción Propiedades del propietario).
        if (Rec."Owner No." = '') and (Rec.GetFilter("Owner No.") <> '') then
            Rec."Owner No." := Rec.GetRangeMax("Owner No.");
        Clear(MarketingTextValue);
        Clear(HouseRulesValue);
        Clear(TransitValue);
        Clear(AccessValue);
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
        MarketingTextValue: Text;
        HouseRulesValue: Text;
        TransitValue: Text;
        AccessValue: Text;
        ShowMapLbl: Label 'Ver en mapa';
}
