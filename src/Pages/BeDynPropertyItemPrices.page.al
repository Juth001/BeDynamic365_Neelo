namespace BeDynamic.PropertyManagement;

using Microsoft.Sales.Pricing;

page 82528 "BeDyn Property Item Prices"
{
    PageType = List;
    SourceTable = "Sales Price";
    SourceTableView = where("Sales Type" = const("All Customers"));
    Caption = 'Precios';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Producto al que aplica el precio.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Variante del producto. Identifica la subpropiedad; en blanco, aplica a la propiedad completa.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unidad de medida del precio (p. ej. noche o mes). En blanco, aplica a cualquier unidad.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cantidad mínima para que aplique el precio.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha desde la que aplica el precio. En blanco, aplica siempre.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha hasta la que aplica el precio. En blanco, sin límite.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Precio unitario de venta.';
                }
            }
        }
    }
}
