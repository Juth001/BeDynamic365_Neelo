namespace BeDynamic.PropertyManagement;

using Microsoft.Inventory.Item.Attribute;
using Microsoft.Sales.Pricing;

page 82523 "BeDyn Property Room Card"
{
    PageType = Card;
    SourceTable = "BeDyn Property Room";
    Caption = 'Ficha subpropiedad';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad a la que pertenece la subpropiedad.';
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número o código de la subpropiedad.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción de la subpropiedad.';
                }
                field("Master Room"; Rec."Master Room")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica que es la subpropiedad master configurada. No se incluye en el cálculo de la capacidad de la propiedad.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Variante del producto de la propiedad que corresponde a esta subpropiedad.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tarea del proyecto de la propiedad que corresponde a esta subpropiedad.';
                }
                field("Room Type Code"; Rec."Room Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tipo de subpropiedad (p. ej. PRIVATE ROOM, ENTIRE HOME), de entre los del tipo de propiedad de la propiedad madre.';
                }
                field("External Id"; Rec."External Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identificador de la subpropiedad en un sistema externo.';
                }
                field("Drive Folder URL"; Rec."Drive Folder URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Carpeta compartida de Google Drive con las imágenes de la subpropiedad. Debe estar compartida como "Cualquier persona con el enlace". Use la acción Importar imágenes de Drive para descargarlas.';
                }
            }
            group(Features)
            {
                Caption = 'Características';

                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Capacidad en personas.';
                }
                field("Square Meters"; Rec."Square Meters")
                {
                    ApplicationArea = All;
                    ToolTip = 'Superficie de la subpropiedad en metros cuadrados.';
                }
                field("Check-In Time"; Rec."Check-In Time")
                {
                    ApplicationArea = All;
                }
                field("Check-Out Time"; Rec."Check-Out Time")
                {
                    ApplicationArea = All;
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
                    ToolTip = 'Texto de marketing de la subpropiedad, con formato enriquecido, para usar en anuncios y portales. Las traducciones se gestionan con la acción Traducciones.';

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
                    ToolTip = 'Normas de la casa (house rules) de la subpropiedad, con formato enriquecido. Las traducciones se gestionan con la acción Traducciones.';

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
            part(RoomDetailsFactbox; "BeDyn Property Room Details")
            {
                ApplicationArea = All;
                Caption = 'Detalles subpropiedad';
                SubPageLink = "Property No." = field("Property No."), "Room No." = field("Room No.");
            }
            part(GalleryFactbox; "BeDyn Property Image Gallery")
            {
                ApplicationArea = All;
                Caption = 'Galería';
                SubPageLink = "Property No." = field("Property No."), "Room No." = field("Room No.");
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Amenities)
            {
                ApplicationArea = All;
                Caption = 'Amenities';
                Image = ServiceItem;
                RunObject = page "BeDyn Property Amenity List";
                RunPageLink = "Property No." = field("Property No."), "Room No." = field("Room No.");
                ToolTip = 'Ver los amenities de esta subpropiedad.';
            }
            action(TextTranslations)
            {
                ApplicationArea = All;
                Caption = 'Traducciones';
                Image = Translations;
                ToolTip = 'Traducciones por idioma de los textos de la subpropiedad (marketing, normas de la casa, cómo llegar y acceso).';

                trigger OnAction()
                var
                    PropertyTextMgt: Codeunit "BeDyn Property Text Mgt.";
                begin
                    PropertyTextMgt.EditTranslations(Rec."Property No.", Rec."Room No.");
                end;
            }
            action(Prices)
            {
                ApplicationArea = All;
                Caption = 'Precios';
                Image = Price;
                ToolTip = 'Ver los precios de venta del producto de la propiedad filtrados por la variante de esta subpropiedad.';

                trigger OnAction()
                begin
                    ShowRoomPrices();
                end;
            }
        }
        area(Processing)
        {
            action(ImportDriveImages)
            {
                ApplicationArea = All;
                Caption = 'Importar imágenes de Drive';
                Image = Import;
                ToolTip = 'Descarga todas las imágenes de la carpeta de Drive de la subpropiedad a su galería. Solo descarga las imágenes nuevas; la primera se usa como portada de la subpropiedad.';

                trigger OnAction()
                var
                    PropertyImageImport: Codeunit "BeDyn Property Image Import";
                begin
                    PropertyImageImport.ImportRoomDriveFolder(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Amenities_Promoted; Amenities)
                {
                }
                actionref(Prices_Promoted; Prices)
                {
                }
                actionref(ImportDriveImages_Promoted; ImportDriveImages)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Property: Record "BeDyn Property";
    begin
        MarketingTextValue := Rec.GetText("BeDyn Property Text Type"::Marketing);
        HouseRulesValue := Rec.GetText("BeDyn Property Text Type"::"House Rules");
        TransitValue := Rec.GetText("BeDyn Property Text Type"::Transit);
        AccessValue := Rec.GetText("BeDyn Property Text Type"::Access);
        // Atributos de la variante del producto asignada a la subpropiedad.
        if Property.Get(Rec."Property No.") then
            CurrPage.ItemAttributesFactbox.Page.LoadItemVariantAttributesData(Property."Item No.", Rec."Variant Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(MarketingTextValue);
        Clear(HouseRulesValue);
        Clear(TransitValue);
        Clear(AccessValue);
    end;

    local procedure ShowRoomPrices()
    var
        Property: Record "BeDyn Property";
        SalesPrice: Record "Sales Price";
    begin
        Property.Get(Rec."Property No.");
        Property.TestField("Item No.");
        SalesPrice.FilterGroup(2);
        SalesPrice.SetRange("Item No.", Property."Item No.");
        SalesPrice.FilterGroup(0);
        SalesPrice.SetRange("Variant Code", Rec."Variant Code");
        Page.Run(Page::"BeDyn Property Item Prices", SalesPrice);
    end;

    var
        MarketingTextValue: Text;
        HouseRulesValue: Text;
        TransitValue: Text;
        AccessValue: Text;
}
