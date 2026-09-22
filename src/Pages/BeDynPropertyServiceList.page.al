namespace BeDynamic.PropertyManagement;

using BeDynamic.CleaningImport;
using Microsoft.Finance.Dimension;

page 82510 "BeDyn Property Service List"
{
    PageType = List;
    SourceTable = "BeDyn Property Service";
    Caption = 'Servicios';
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código del servicio (p. ej. LIMPIEZA, PLANCHADO, MINIBAR).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del servicio.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensiones';
                Image = Dimensions;
                ShortcutKey = 'Alt+D';
                RunObject = page "Default Dimensions";
                RunPageLink = "Table ID" = const(Database::"BeDyn Property Service"), "No." = field("Code");
                ToolTip = 'Dimensiones predeterminadas del servicio. Se añaden a las líneas que genera: facturas de servicios de reserva y diario de reclasificación de limpiezas.';
            }
            action(VendorServices)
            {
                ApplicationArea = All;
                Caption = 'Servicios por proveedor';
                Image = ServiceItem;
                RunObject = page "BeDyn Cleaning Services";
                RunPageLink = Code = field(Code);
                ToolTip = 'Catálogo de servicios por proveedor filtrado por el servicio seleccionado: cuenta de gasto, tarea estándar y precio pactado de cada proveedor.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(VendorServices_Promoted; VendorServices)
                {
                }
            }
        }
    }
}
