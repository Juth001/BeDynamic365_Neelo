namespace BeDynamic.PropertyManagement;

using BeDynamic.CleaningImport;
using BeDynamic.PleoImport;
using BeDynamic.PortalImport;
using BeDynamic.PropertyWizard;
using BeDynamic.ReservationImport;
using Neelo.RecurringInvoicing;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Security.User;

page 82538 "BeDyn Property Manager RC"
{
    Caption = 'Gestión de Propiedades';
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
            part(Headline; "BeDyn Property RC Headline")
            {
                ApplicationArea = All;
            }
            part(Activities; "BeDyn Property Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Embedding)
        {
            action(Properties)
            {
                ApplicationArea = All;
                Caption = 'Propiedades';
                RunObject = page "BeDyn Property List";
                ToolTip = 'Ver y gestionar las propiedades.';
            }
            action(Owners)
            {
                ApplicationArea = All;
                Caption = 'Propietarios';
                RunObject = page "BeDyn Property Owner List";
                ToolTip = 'Ver y gestionar los propietarios.';
            }
            action(Contracts)
            {
                ApplicationArea = All;
                Caption = 'Contratos';
                RunObject = page "BeDyn Property Contract List";
                ToolTip = 'Ver y gestionar los contratos de propiedad.';
            }
            action(Tenants)
            {
                ApplicationArea = All;
                Caption = 'Inquilinos';
                RunObject = page "BeDyn Tenant List";
                ToolTip = 'Ver y gestionar los inquilinos.';
            }
            action(Reservations)
            {
                ApplicationArea = All;
                Caption = 'Reservas';
                RunObject = page "BeDyn Reservation List";
                ToolTip = 'Ver y gestionar las reservas.';
            }
            action(Deposits)
            {
                ApplicationArea = All;
                Caption = 'Fianzas';
                RunObject = page "BeDyn Deposit List";
                ToolTip = 'Ver y gestionar las fianzas.';
            }
        }
        area(Sections)
        {
            group(PropertiesSection)
            {
                Caption = 'Propiedades';
                ToolTip = 'Propiedades, subpropiedades, equipamiento e imágenes.';

                action(PropertyList)
                {
                    ApplicationArea = All;
                    Caption = 'Propiedades';
                    RunObject = page "BeDyn Property List";
                    ToolTip = 'Ver y gestionar las propiedades.';
                }
                action(PropertyRooms)
                {
                    ApplicationArea = All;
                    Caption = 'Subpropiedades';
                    RunObject = page "BeDyn Property Room List";
                    ToolTip = 'Ver las subpropiedades de todas las propiedades.';
                }
                action(OwnerList)
                {
                    ApplicationArea = All;
                    Caption = 'Propietarios';
                    RunObject = page "BeDyn Property Owner List";
                    ToolTip = 'Ver y gestionar los propietarios.';
                }
                action(PropertyAmenities)
                {
                    ApplicationArea = All;
                    Caption = 'Equipamiento por propiedad';
                    RunObject = page "BeDyn Property Amenity List";
                    ToolTip = 'Ver el equipamiento asignado a cada propiedad.';
                }
                action(PropertyImages)
                {
                    ApplicationArea = All;
                    Caption = 'Imágenes de propiedades';
                    RunObject = page "BeDyn Property Image List";
                    ToolTip = 'Ver las imágenes registradas de las propiedades.';
                }
            }
            group(RentalSection)
            {
                Caption = 'Alquiler y reservas';
                ToolTip = 'Contratos, inquilinos, reservas y fianzas.';

                action(ContractList)
                {
                    ApplicationArea = All;
                    Caption = 'Contratos';
                    RunObject = page "BeDyn Property Contract List";
                    ToolTip = 'Ver y gestionar los contratos de propiedad.';
                }
                action(TenantList)
                {
                    ApplicationArea = All;
                    Caption = 'Inquilinos';
                    RunObject = page "BeDyn Tenant List";
                    ToolTip = 'Ver y gestionar los inquilinos.';
                }
                action(ReservationList)
                {
                    ApplicationArea = All;
                    Caption = 'Reservas';
                    RunObject = page "BeDyn Reservation List";
                    ToolTip = 'Ver y gestionar las reservas.';
                }
                action(AvailabilityCalendar)
                {
                    ApplicationArea = All;
                    Caption = 'Calendario de disponibilidad';
                    RunObject = page "BeDyn Room Avail. Calendar";
                    ToolTip = 'Consultar la disponibilidad de las subpropiedades.';
                }
                action(DepositList)
                {
                    ApplicationArea = All;
                    Caption = 'Fianzas';
                    RunObject = page "BeDyn Deposit List";
                    ToolTip = 'Ver y gestionar las fianzas.';
                }
                action(ServiceList)
                {
                    ApplicationArea = All;
                    Caption = 'Servicios';
                    RunObject = page "BeDyn Property Service List";
                    ToolTip = 'Ver y gestionar los servicios facturables.';
                }
            }
            group(BillingSection)
            {
                Caption = 'Facturación';
                ToolTip = 'Precios, facturas y generación de facturas de alquiler.';

                action(ItemPrices)
                {
                    ApplicationArea = All;
                    Caption = 'Precios por propiedad';
                    RunObject = page "BeDyn Property Item Prices";
                    ToolTip = 'Ver y gestionar los precios de venta por propiedad.';
                }
                action(SalesInvoices)
                {
                    ApplicationArea = All;
                    Caption = 'Facturas de venta';
                    RunObject = page "Sales Invoice List";
                    ToolTip = 'Ver las facturas de venta pendientes de registrar.';
                }
                action(PostedSalesInvoices)
                {
                    ApplicationArea = All;
                    Caption = 'Facturas de venta registradas';
                    RunObject = page "Posted Sales Invoices";
                    ToolTip = 'Ver el histórico de facturas de venta registradas.';
                }
                action(GenerateRentInvoices)
                {
                    ApplicationArea = All;
                    Caption = 'Generar facturas de alquiler';
                    RunObject = report "BeDyn Gen. Monthly Rent Inv.";
                    ToolTip = 'Generar las facturas mensuales de alquiler de los contratos activos.';
                }
            }
            group(ImportsSection)
            {
                Caption = 'Importaciones';
                ToolTip = 'Importación de gastos de Pleo, gastos de limpieza, reservas de Airbnb y Booking y facturación recurrente.';

                action(ReservationImportWorksheet)
                {
                    ApplicationArea = All;
                    Caption = 'Hoja importación reservas';
                    RunObject = page "BeDyn Res. Import Wksh.";
                    ToolTip = 'Importar el fichero de cuadre de reservas y fianzas: crea inquilinos, reservas y fianzas.';
                }
                action(PleoWorksheet)
                {
                    ApplicationArea = All;
                    Caption = 'Hoja importación Pleo';
                    RunObject = page "BeDyn Pleo Import Worksheet";
                    ToolTip = 'Importar y procesar los gastos exportados de Pleo.';
                }
                action(PortalWorksheet)
                {
                    ApplicationArea = All;
                    Caption = 'Hoja importación portales';
                    RunObject = page "BeDyn Portal Import Worksheet";
                    ToolTip = 'Importar y procesar las reservas y payouts exportados de Airbnb y Booking; el canal se detecta automáticamente al subir el fichero.';
                }
                action(CleaningWorksheet)
                {
                    ApplicationArea = All;
                    Caption = 'Hoja importación limpiezas';
                    RunObject = page "BeDyn Cleaning Import Wksh.";
                    ToolTip = 'Importar y procesar el fichero mensual de gastos del proveedor de limpieza.';
                }
                action(RecurringInvImport)
                {
                    ApplicationArea = All;
                    Caption = 'Importación facturación recurrente';
                    RunObject = page "BeDyn Invoice Import Buffer";
                    ToolTip = 'Importar y procesar los CSV de facturación recurrente, tanto la plantilla estándar como la de particulares.';
                }
                action(ImportPropertyImages)
                {
                    ApplicationArea = All;
                    Caption = 'Importar imágenes de propiedades';
                    RunObject = codeunit "BeDyn Property Image Import";
                    ToolTip = 'Importar imágenes desde un CSV con nº de propiedad, nº de subpropiedad y URL de descarga.';
                }
                group(ImportArchives)
                {
                    Caption = 'Archivos';
                    ToolTip = 'Históricos de las líneas de importación ya procesadas.';

                    action(PleoArchive)
                    {
                        ApplicationArea = All;
                        Caption = 'Histórico gastos Pleo';
                        RunObject = page "BeDyn Pleo Expense Archive";
                        ToolTip = 'Consultar los gastos de Pleo ya procesados.';
                    }
                    action(PortalArchive)
                    {
                        ApplicationArea = All;
                        Caption = 'Histórico importación portales';
                        RunObject = page "BeDyn Portal Import Archive";
                        ToolTip = 'Consultar las líneas de reservas y payouts de portales ya procesadas.';
                    }
                    action(RecurringInvArchive)
                    {
                        ApplicationArea = All;
                        Caption = 'Histórico facturación recurrente';
                        RunObject = page "BeDyn Invoice Import Archive";
                        ToolTip = 'Consultar las líneas de facturación recurrente ya procesadas y archivadas.';
                    }
                }
            }
            group(PortalsSection)
            {
                Caption = 'Portales';
                ToolTip = 'Portales de publicación de propiedades.';

                action(Portals)
                {
                    ApplicationArea = All;
                    Caption = 'Portales';
                    RunObject = page "BeDyn Portal List";
                    ToolTip = 'Ver y gestionar los portales de publicación.';
                }
            }
            group(SetupSection)
            {
                Caption = 'Configuración';
                ToolTip = 'Configuración y catálogos del módulo.';

                action(WizardSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Configuración asistente propiedades';
                    RunObject = page "BeDyn Property Setup";
                    ToolTip = 'Dimensiones, plantilla de producto y cliente genérico que usa el asistente de alta de propiedades.';
                }
                action(PropertyMgtCompanies)
                {
                    ApplicationArea = All;
                    Caption = 'Empresas gestoras';
                    RunObject = page "BeDyn Property Mgt. Companies";
                    ToolTip = 'Empresas gestoras que dan el segundo segmento del código de propiedad.';
                }
                action(PropertyTaskTemplates)
                {
                    ApplicationArea = All;
                    Caption = 'Plantilla de tareas de propiedad';
                    RunObject = page "BeDyn Property Task Templates";
                    ToolTip = 'Tareas que se crean en el proyecto de cada propiedad nueva.';
                }
                action(CustomerTypes)
                {
                    ApplicationArea = All;
                    Caption = 'Tipos de cliente';
                    RunObject = page "BeDyn Customer Types";
                    ToolTip = 'Tipos de cliente de la ficha del inquilino, que heredan sus reservas.';
                }
                action(GuestTypes)
                {
                    ApplicationArea = All;
                    Caption = 'Tipos de huésped';
                    RunObject = page "BeDyn Guest Types";
                    ToolTip = 'Tipos de huésped que se asignan a cada reserva.';
                }
                action(CleaningServiceCatalog)
                {
                    ApplicationArea = All;
                    Caption = 'Catálogo de servicios de limpieza';
                    RunObject = page "BeDyn Cleaning Services";
                    ToolTip = 'Servicios de limpieza por proveedor: cuenta de gasto, tarea estándar y precio pactado.';
                }
                action(UserSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Configuración de usuarios';
                    RunObject = page "User Setup";
                    ToolTip = 'Configuración de usuarios, donde se marca quién puede renumerar propiedades.';
                }
                action(Setup)
                {
                    ApplicationArea = All;
                    Caption = 'Configuración de propiedades';
                    RunObject = page "BeDyn Property Mgt. Setup";
                    ToolTip = 'Configurar las series numéricas y opciones generales del módulo.';
                }
                action(PleoSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Configuración Pleo';
                    RunObject = page "BeDyn Pleo Setup";
                    ToolTip = 'Configurar la importación de gastos de Pleo.';
                }
                action(PortalSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Configuración portales';
                    RunObject = page "BeDyn Portal Setup";
                    ToolTip = 'Configurar la importación de reservas y payouts de Airbnb y Booking.';
                }
                action(PortalListingMapping)
                {
                    ApplicationArea = All;
                    Caption = 'Mapeo alojamientos portales';
                    RunObject = page "BeDyn Portal Listing Mapping";
                    ToolTip = 'Asignar cada alojamiento de Airbnb y Booking a su propiedad.';
                }
                action(RecurringInvSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Configuración facturación recurrente';
                    RunObject = page "BeDyn Recurring Inv. Setup";
                    ToolTip = 'Configurar la importación de facturación recurrente: fichero CSV, registro automático y dimensión de línea de negocio.';
                }
                action(BillingCodes)
                {
                    ApplicationArea = All;
                    Caption = 'Códigos de facturación';
                    RunObject = page "BeDyn Billing Codes";
                    ToolTip = 'Gestionar los códigos de facturación que enlazan las filas del CSV con la configuración de facturación de cada cliente.';
                }
                action(PropertyTypes)
                {
                    ApplicationArea = All;
                    Caption = 'Tipos de propiedad';
                    RunObject = page "BeDyn Property Types";
                    ToolTip = 'Gestionar los tipos de propiedad.';
                }
                action(PropertyStatuses)
                {
                    ApplicationArea = All;
                    Caption = 'Estados de propiedad';
                    RunObject = page "BeDyn Property Statuses";
                    ToolTip = 'Gestionar los estados de propiedad.';
                }
                action(RoomTypes)
                {
                    ApplicationArea = All;
                    Caption = 'Tipos de subpropiedad';
                    RunObject = page "BeDyn Room Types";
                    ToolTip = 'Gestionar los tipos de subpropiedad.';
                }
                action(StayTypes)
                {
                    ApplicationArea = All;
                    Caption = 'Tipos de estancia';
                    RunObject = page "BeDyn Stay Types";
                    ToolTip = 'Gestionar los tipos de estancia.';
                }
                action(AmenityTypes)
                {
                    ApplicationArea = All;
                    Caption = 'Tipos de equipamiento';
                    RunObject = page "BeDyn Amenity Types";
                    ToolTip = 'Gestionar los tipos de equipamiento.';
                }
                action(Amenities)
                {
                    ApplicationArea = All;
                    Caption = 'Equipamientos';
                    RunObject = page "BeDyn Amenities";
                    ToolTip = 'Gestionar el catálogo de equipamientos.';
                }
            }
        }
        area(Creation)
        {
            action(PropertyWizard)
            {
                ApplicationArea = All;
                Caption = 'Alta asistida de propiedad';
                Image = New;
                RunObject = page "BeDyn Property Wizard";
                ToolTip = 'Crear una propiedad completa con el asistente: producto con variantes, valor de dimensión, proyecto y ficha de propiedad.';
            }
            action(NewProperty)
            {
                ApplicationArea = All;
                Caption = 'Propiedad';
                Image = NewItem;
                RunObject = page "BeDyn Property Card";
                RunPageMode = Create;
                ToolTip = 'Crear una nueva propiedad.';
            }
            action(NewContract)
            {
                ApplicationArea = All;
                Caption = 'Contrato';
                Image = NewDocument;
                RunObject = page "BeDyn Property Contract Card";
                RunPageMode = Create;
                ToolTip = 'Crear un nuevo contrato de propiedad.';
            }
            action(NewReservation)
            {
                ApplicationArea = All;
                Caption = 'Reserva';
                Image = NewDocument;
                RunObject = page "BeDyn Reservation Card";
                RunPageMode = Create;
                ToolTip = 'Crear una nueva reserva.';
            }
            action(NewTenant)
            {
                ApplicationArea = All;
                Caption = 'Inquilino';
                Image = NewCustomer;
                RunObject = page "BeDyn Tenant Card";
                RunPageMode = Create;
                ToolTip = 'Registrar un nuevo inquilino.';
            }
        }
        area(Processing)
        {
            action(RunAvailabilityCalendar)
            {
                ApplicationArea = All;
                Caption = 'Calendario de disponibilidad';
                Image = Calendar;
                RunObject = page "BeDyn Room Avail. Calendar";
                ToolTip = 'Consultar la disponibilidad de las subpropiedades.';
            }
            action(RunGenerateRentInvoices)
            {
                ApplicationArea = All;
                Caption = 'Generar facturas de alquiler';
                Image = CreateDocuments;
                RunObject = report "BeDyn Gen. Monthly Rent Inv.";
                ToolTip = 'Generar las facturas mensuales de alquiler de los contratos activos.';
            }
        }
        area(Reporting)
        {
            action(AmenityInventory)
            {
                ApplicationArea = All;
                Caption = 'Inventario de equipamiento';
                Image = Report;
                RunObject = report "BeDyn Prop. Amenity Inventory";
                ToolTip = 'Imprimir el inventario de equipamiento por propiedad.';
            }
            action(PropertyCodeCheck)
            {
                ApplicationArea = All;
                Caption = 'Comparación maestros de propiedad';
                Image = Report;
                RunObject = report "BeDyn Property Code Check";
                ToolTip = 'Comparar producto, valor de dimensión, proyecto y propiedad, y señalar los que faltan o han dejado de coincidir.';
            }
        }
    }
}
