namespace BeDynamic.PropertyManagement;

using BeDynamic.CleaningImport;
using BeDynamic.ReservationImport;

page 82500 "BeDyn Property Mgt. Setup"
{
    PageType = Card;
    SourceTable = "BeDyn Property Mgt. Setup";
    Caption = 'Configuración gestión propiedades';
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Numbering)
            {
                Caption = 'Numeración';

                field("Owner Nos."; Rec."Owner Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Serie numérica para los propietarios.';
                }
                field("Property Nos."; Rec."Property Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Serie numérica para las propiedades.';
                }
                field("Contract Nos."; Rec."Contract Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Serie numérica para los contratos.';
                }
                field("Tenant Nos."; Rec."Tenant Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Serie numérica para los inquilinos.';
                }
                field("Reservation Nos."; Rec."Reservation Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Serie numérica para las reservas.';
                }
                field("Deposit Nos."; Rec."Deposit Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Serie numérica para las fianzas.';
                }
            }
            group(Properties)
            {
                Caption = 'Propiedades';

                field("Master Room Code"; Rec."Master Room Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código de la subpropiedad master. Al crear una nueva propiedad se crea automáticamente una subpropiedad con este código.';
                }
                field("Link Property Codes"; Rec."Link Property Codes")
                {
                    ApplicationArea = All;
                }
            }
            group(Prices)
            {
                Caption = 'Precios';

                field("Night Unit of Measure Code"; Rec."Night Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unidad de medida que identifica el precio por noche en las listas de precios del producto.';
                }
                field("Month Unit of Measure Code"; Rec."Month Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unidad de medida que identifica el precio por mes en las listas de precios del producto.';
                }
            }
            group(Billing)
            {
                Caption = 'Facturación';

                field("Def. Billing Moment"; Rec."Def. Billing Moment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Momento de facturación por defecto para las reservas por noche: al check-in (prepago) o al check-out. Se propone en las nuevas propiedades.';
                }
                field("Auto-Post Rental Invoices"; Rec."Auto-Post Rental Invoices")
                {
                    ApplicationArea = All;
                    ToolTip = 'Si está activado, las facturas generadas se registran automáticamente. Si no, se crean como borrador para revisarlas y registrarlas manualmente.';
                }
                field("Deposit Billing Method"; Rec."Deposit Billing Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cómo se cobra la fianza: como línea sin IVA en la primera factura de la reserva mensual, o aparte sin factura (marcando el cobro manualmente en la fianza).';
                }
                field("Deposit G/L Account No."; Rec."Deposit G/L Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta contable de pasivo donde se abona la fianza cobrada (p. ej. 561 Depósitos recibidos a corto plazo). Debe admitir registro directo y tener configurado IVA exento/no sujeto.';
                }
                field("Deposit Bridge Account No."; Rec."Deposit Bridge Account No.")
                {
                    ApplicationArea = All;
                }
                field("Post Deposits on Import"; Rec."Post Deposits on Import")
                {
                    ApplicationArea = All;
                }
                field("Service G/L Account No."; Rec."Service G/L Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta de ingresos por defecto para facturar los servicios de las reservas que no tengan cuenta propia.';
                }
            }
            group(ReservationImport)
            {
                Caption = 'Importación de reservas';

                field("Channel Dimension Code"; Rec."Channel Dimension Code")
                {
                    ApplicationArea = All;
                }
                field("Res. Import Duplicate Action"; Rec."Res. Import Duplicate Action")
                {
                    ApplicationArea = All;
                }
                field("Res. Import Create Masters"; Rec."Res. Import Create Masters")
                {
                    ApplicationArea = All;
                }
            }
            group(CleaningServices)
            {
                Caption = 'Servicios de limpieza';

                field("Cleaning Vendor No."; Rec."Cleaning Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Bridge Account No."; Rec."Cleaning Bridge Account No.")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Posting Mode"; Rec."Cleaning Posting Mode")
                {
                    ApplicationArea = All;
                }
                field("Property Dim. Source"; Rec."Property Dim. Source")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Auto Post Reclass"; Rec."Cleaning Auto Post Reclass")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Jnl. Template Name"; Rec."Cleaning Jnl. Template Name")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Jnl. Batch Name"; Rec."Cleaning Jnl. Batch Name")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Match Tolerance"; Rec."Cleaning Match Tolerance")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Check Acc. Period"; Rec."Cleaning Check Acc. Period")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Check GL Setup Date"; Rec."Cleaning Check GL Setup Date")
                {
                    ApplicationArea = All;
                }
                field("Cleaning Check User Setup Date"; Rec."Cleaning Check User Setup Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportImages)
            {
                ApplicationArea = All;
                Caption = 'Importar imágenes';
                Image = Import;
                ToolTip = 'Importa imágenes desde un archivo CSV con columnas: nº propiedad; nº subpropiedad; URL de descarga. Con la subpropiedad en blanco la imagen se inserta en el producto de la propiedad; con subpropiedad, en la variante correspondiente.';

                trigger OnAction()
                var
                    PropertyImageImport: Codeunit "BeDyn Property Image Import";
                begin
                    PropertyImageImport.ImportFromCsv();
                end;
            }
            action(PropertyCodeCheck)
            {
                ApplicationArea = All;
                Caption = 'Comparar maestros de propiedad';
                Image = CompareCOA;
                RunObject = report "BeDyn Property Code Check";
                ToolTip = 'Compara los cuatro maestros que comparten código en cada propiedad (producto, valor de dimensión, proyecto y propiedad) y señala los que faltan o han dejado de coincidir.';
            }
        }
        area(Navigation)
        {
            action(PropertyServices)
            {
                ApplicationArea = All;
                Caption = 'Servicios';
                Image = List;
                RunObject = page "BeDyn Property Service List";
                ToolTip = 'Tabla de servicios: los códigos de servicio con su descripción y sus dimensiones predeterminadas.';
            }
            action(ReservationImportWorksheet)
            {
                ApplicationArea = All;
                Caption = 'Hoja importación reservas';
                Image = Worksheet;
                RunObject = page "BeDyn Res. Import Wksh.";
                ToolTip = 'Abre la hoja de trabajo para importar el fichero de cuadre de reservas y fianzas.';
            }
            action(CustomerTypes)
            {
                ApplicationArea = All;
                Caption = 'Tipos de cliente';
                Image = CustomerGroup;
                RunObject = page "BeDyn Customer Types";
                ToolTip = 'Tipos de cliente que se asignan a la ficha del inquilino y heredan sus reservas.';
            }
            action(GuestTypes)
            {
                ApplicationArea = All;
                Caption = 'Tipos de huésped';
                Image = Users;
                RunObject = page "BeDyn Guest Types";
                ToolTip = 'Tipos de huésped que se asignan a cada reserva.';
            }
            action(CleaningWorksheet)
            {
                ApplicationArea = All;
                Caption = 'Hoja importación limpiezas';
                Image = Worksheet;
                RunObject = page "BeDyn Cleaning Import Wksh.";
                ToolTip = 'Abre la hoja de trabajo de importación del fichero mensual del proveedor de limpieza.';
            }
            action(CleaningServiceCatalog)
            {
                ApplicationArea = All;
                Caption = 'Catálogo de servicios por proveedor';
                Image = ServiceItem;
                RunObject = page "BeDyn Cleaning Services";
                ToolTip = 'Catálogo de servicios por proveedor: columnas del fichero, cuenta de gasto, tarea estándar y precio pactado de cada servicio.';
            }
            action(CleaningPendingInvoices)
            {
                ApplicationArea = All;
                Caption = 'Facturas limpieza pendientes';
                Image = PurchaseInvoice;
                RunObject = page "BeDyn Cleaning Pending Inv.";
                ToolTip = 'Facturas registradas del proveedor de limpieza con su importe asignado, reclasificado y pendiente de distribuir.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ImportImages_Promoted; ImportImages)
                {
                }
                actionref(PropertyServices_Promoted; PropertyServices)
                {
                }
                actionref(CleaningWorksheet_Promoted; CleaningWorksheet)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetInstance();
    end;
}
