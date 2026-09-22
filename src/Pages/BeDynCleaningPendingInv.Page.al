namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using Microsoft.Purchases.History;

page 82701 "BeDyn Cleaning Pending Inv."
{
    PageType = List;
    SourceTable = "Purch. Inv. Header";
    SourceTableView = sorting("Posting Date") order(descending);
    Caption = 'Facturas limpieza pendientes de distribuir';
    UsageCategory = Tasks;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Invoices)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Número de la factura de compra registrada.';
                    StyleExpr = CoverageStyle;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Fecha de registro de la factura.';
                    StyleExpr = CoverageStyle;
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ToolTip = 'Número de factura del proveedor.';
                    StyleExpr = CoverageStyle;
                }
                field(Amount; Rec.Amount)
                {
                    Caption = 'Base imponible';
                    ToolTip = 'Base imponible de la factura: el importe que debe quedar cubierto por las líneas de la hoja de importación.';
                    StyleExpr = CoverageStyle;
                }
                field(AssignedAmount; AssignedAmount)
                {
                    Caption = 'Asignado';
                    AutoFormatType = 1;
                    ToolTip = 'Suma de las líneas de la hoja de importación asignadas a esta factura (en cualquier estado).';
                    StyleExpr = CoverageStyle;

                    trigger OnDrillDown()
                    begin
                        DrillDownLines();
                    end;
                }
                field(PostedAmount; PostedAmount)
                {
                    Caption = 'Reclasificado';
                    AutoFormatType = 1;
                    ToolTip = 'Suma de las líneas de esta factura ya reclasificadas.';
                    StyleExpr = CoverageStyle;
                }
                field(RemainingAmount; RemainingAmount)
                {
                    Caption = 'Pendiente';
                    AutoFormatType = 1;
                    ToolTip = 'Base imponible menos el importe asignado: lo que falta por cubrir con líneas de la hoja de importación.';
                    StyleExpr = CoverageStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenInvoice)
            {
                ApplicationArea = All;
                Caption = 'Ver factura';
                Image = ViewDocumentLine;
                ToolTip = 'Abre la factura de compra registrada.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Posted Purchase Invoice", Rec);
                end;
            }
            action(OpenWorksheet)
            {
                ApplicationArea = All;
                Caption = 'Ver líneas asignadas';
                Image = Worksheet;
                ToolTip = 'Abre la hoja de importación filtrada por las líneas asignadas a esta factura.';

                trigger OnAction()
                begin
                    DrillDownLines();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(OpenInvoice_Promoted; OpenInvoice)
                {
                }
                actionref(OpenWorksheet_Promoted; OpenWorksheet)
                {
                }
            }
        }
    }

    var
        ReclassMgt: Codeunit "BeDyn Cleaning Reclass Mgt.";
        AssignedAmount: Decimal;
        PostedAmount: Decimal;
        RemainingAmount: Decimal;
        CoverageStyle: Text;
        MatchTolerance: Decimal;

    trigger OnOpenPage()
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        VendorFilter: Text;
    begin
        PropertySetup.GetInstance();
        MatchTolerance := PropertySetup."Cleaning Match Tolerance";
        // Se muestran las facturas de todos los proveedores con catálogo de
        // servicios (o del proveedor habitual, si el catálogo aún está vacío).
        VendorFilter := BuildCatalogVendorFilter();
        if (VendorFilter = '') and (PropertySetup."Cleaning Vendor No." <> '') then
            VendorFilter := '''' + PropertySetup."Cleaning Vendor No." + '''';
        if VendorFilter <> '' then
            Rec.SetFilter("Buy-from Vendor No.", VendorFilter);
    end;

    local procedure BuildCatalogVendorFilter() VendorFilter: Text
    var
        CleaningService: Record "BeDyn Cleaning Service";
        LastVendorNo: Code[20];
    begin
        if not CleaningService.FindSet() then
            exit('');
        repeat
            if CleaningService."Vendor No." <> LastVendorNo then begin
                if VendorFilter <> '' then
                    VendorFilter += '|';
                VendorFilter += '''' + CleaningService."Vendor No." + '''';
                LastVendorNo := CleaningService."Vendor No.";
            end;
        until CleaningService.Next() = 0;
    end;

    trigger OnAfterGetRecord()
    var
        BaseAmount: Decimal;
    begin
        Rec.CalcFields(Amount);
        ReclassMgt.GetInvoiceCoverage(Rec."No.", BaseAmount, AssignedAmount, PostedAmount);
        RemainingAmount := Rec.Amount - AssignedAmount;
        case true of
            Abs(Rec.Amount - PostedAmount) <= MatchTolerance:
                CoverageStyle := 'Favorable';
            AssignedAmount = 0:
                CoverageStyle := 'Attention';
            else
                CoverageStyle := 'Ambiguous';
        end;
    end;

    local procedure DrillDownLines()
    var
        ImportLine: Record "BeDyn Cleaning Import Line";
    begin
        ImportLine.SetRange("Invoice No.", Rec."No.");
        Page.Run(Page::"BeDyn Cleaning Import Wksh.", ImportLine);
    end;
}
