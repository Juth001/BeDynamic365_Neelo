namespace BeDynamic.PropertyManagement;

report 82500 "BeDyn Prop. Amenity Inventory"
{
    ApplicationArea = All;
    Caption = 'Inventario de amenities';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(Property; "BeDyn Property")
        {
            RequestFilterFields = "No.", "Owner No.";
            PrintOnlyIfDetail = true;

            column(PropertyNo; "No.")
            {
            }
            column(PropertyName; Name)
            {
            }
            dataitem(PropertyAmenity; "BeDyn Property Amenity")
            {
                DataItemLink = "Property No." = field("No.");
                DataItemTableView = sorting("Property No.", "Room No.");
                RequestFilterFields = Location, "Room No.";

                column(LocationText; Format(Location))
                {
                }
                column(RoomNo; "Room No.")
                {
                }
                column(AmenityCode; "Amenity Code")
                {
                }
                column(AmenityDescription; Description)
                {
                }
                column(AmenityTypeCode; "Amenity Type Code")
                {
                }
                column(Brand; Brand)
                {
                }
                column(SerialNo; "Serial No.")
                {
                }
                column(StatusText; Format(Status))
                {
                }
            }
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            // Ruta relativa a la raíz del proyecto (app.json), no a la carpeta del módulo.
            LayoutFile = 'src/Reports/PropertyAmenityInventory.rdlc';
            Caption = 'Inventario de amenities';
        }
    }
}
