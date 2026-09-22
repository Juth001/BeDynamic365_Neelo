namespace BeDynamic.PropertyManagement;

using Microsoft.Inventory.Item.Attribute;
using Microsoft.Sales.Pricing;

page 82529 "BeDyn Property Room List"
{
    PageType = List;
    SourceTable = "BeDyn Property Room";
    Caption = 'Subpropiedades';
    CardPageId = "BeDyn Property Room Card";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad a la que pertenece la subpropiedad.';
                    Visible = false;
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
                field("External Id"; Rec."External Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identificador de la subpropiedad en un sistema externo.';
                }
                field("Drive Folder URL"; Rec."Drive Folder URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Carpeta compartida de Google Drive con las imágenes de la subpropiedad. Debe estar compartida como "Cualquier persona con el enlace".';
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
            part(RoomPictureFactbox; "BeDyn Property Room Picture")
            {
                ApplicationArea = All;
                Caption = 'Imagen';
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
            action(AvailabilityCalendar)
            {
                ApplicationArea = All;
                Caption = 'Calendario disponibilidad';
                Image = Calendar;
                RunObject = page "BeDyn Room Avail. Calendar";
                RunPageLink = "Property No." = field("Property No.");
                ToolTip = 'Ver la disponibilidad de las subpropiedades de esta propiedad en un calendario mensual.';
            }
            action(ImportDriveImages)
            {
                ApplicationArea = All;
                Caption = 'Importar imágenes de Drive';
                Image = Import;
                ToolTip = 'Descarga todas las imágenes de la carpeta de Drive de la subpropiedad seleccionada a su galería. Solo descarga las imágenes nuevas; la primera se usa como portada de la subpropiedad.';

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
                actionref(AvailabilityCalendar_Promoted; AvailabilityCalendar)
                {
                }
                actionref(ImportDriveImages_Promoted; ImportDriveImages)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Property: Record "BeDyn Property";
    begin
        // Atributos de la variante del producto asignada a la subpropiedad.
        if Property.Get(Rec."Property No.") then
            CurrPage.ItemAttributesFactbox.Page.LoadItemVariantAttributesData(Property."Item No.", Rec."Variant Code");
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
}
