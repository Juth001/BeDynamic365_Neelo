namespace Neelo.DebtManagement;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.NoSeries;

// Gestión de deuda: cabecera de cada préstamo/deuda con la entidad. El capital,
// intereses y total pendientes se calculan desde su cuadro de amortización: la
// suma de las cuotas no marcadas como pagadas. El cuadro puede generarse con la
// acción Calcular cuotas (sistema francés).
table 81100 "BeDyn Debt"
{
    Caption = 'Deuda';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Debt List";
    DrillDownPageId = "BeDyn Debt List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Nº';
            ToolTip = 'Número de la deuda, de la serie configurada; admite numeración manual si la serie lo permite.';

            trigger OnValidate()
            var
                CarteraSetup: Record "Cartera Setup";
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    CarteraSetup.Get();
                    NoSeries.TestManual(CarteraSetup."BeDyn Debt Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Descripción';
            ToolTip = 'Descripción de la deuda.';
        }
        field(3; Entity; Code[20])
        {
            Caption = 'Entidad';
            TableRelation = "Bank Account";
            ToolTip = 'Cuenta bancaria de la entidad financiera prestamista.';
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Fecha';
            ToolTip = 'Fecha de formalización de la deuda. La primera cuota calculada vence en esta fecha.';
        }
        field(5; "End Date"; Date)
        {
            Caption = 'Fecha vencimiento';
            ToolTip = 'Fecha de vencimiento de la deuda.';

            trigger OnValidate()
            var
                InvalidDatesErr: Label 'La fecha de vencimiento debe ser posterior a la fecha de formalización.';
            begin
                if ("Start Date" <> 0D) and ("End Date" <> 0D) and ("End Date" < "Start Date") then
                    Error(InvalidDatesErr);
            end;
        }
        field(6; Capital; Decimal)
        {
            Caption = 'Capital solicitado';
            MinValue = 0;
            AutoFormatType = 1;
            ToolTip = 'Capital solicitado a la entidad.';
        }
        field(7; "Interest Rate %"; Decimal)
        {
            Caption = 'Tipo de interés %';
            MinValue = 0;
            DecimalPlaces = 2 : 5;
            ToolTip = 'Tipo de interés nominal anual de la deuda.';
        }
        field(8; "No. of Installments"; Integer)
        {
            Caption = 'Nº cuotas';
            FieldClass = FlowField;
            CalcFormula = count("BeDyn Debt Amortization Line" where("Debt No." = field("No.")));
            Editable = false;
            ToolTip = 'Número de cuotas del cuadro de amortización.';
        }
        field(10; "Pending Principal"; Decimal)
        {
            Caption = 'Capital pendiente';
            FieldClass = FlowField;
            CalcFormula = sum("BeDyn Debt Amortization Line"."Principal Amount" where("Debt No." = field("No."), Paid = const(false)));
            Editable = false;
            AutoFormatType = 1;
            ToolTip = 'Suma del importe principal de las cuotas pendientes de pago.';
        }
        field(11; "Pending Interest"; Decimal)
        {
            Caption = 'Intereses pendientes';
            FieldClass = FlowField;
            CalcFormula = sum("BeDyn Debt Amortization Line"."Interest Amount" where("Debt No." = field("No."), Paid = const(false)));
            Editable = false;
            AutoFormatType = 1;
            ToolTip = 'Suma de los intereses de las cuotas pendientes de pago.';
        }
        field(12; "Pending Total"; Decimal)
        {
            Caption = 'Total pendiente';
            FieldClass = FlowField;
            CalcFormula = sum("BeDyn Debt Amortization Line"."Total Amount" where("Debt No." = field("No."), Paid = const(false)));
            Editable = false;
            AutoFormatType = 1;
            ToolTip = 'Suma del total de las cuotas pendientes de pago (principal + intereses).';
        }
        field(13; "No. of Payments"; Integer)
        {
            Caption = 'Nº pagos';
            MinValue = 0;
            ToolTip = 'Número de pagos programados del préstamo, para calcular el cuadro de amortización.';
        }
        field(14; "Payments per Year"; Integer)
        {
            Caption = 'Pagos por año';
            MinValue = 1;
            MaxValue = 12;
            InitValue = 12;
            ToolTip = 'Número de pagos por año (12 = mensual, 4 = trimestral...). Determina la periodicidad de las cuotas y el interés de cada periodo.';
        }
        field(15; "Additional Payment"; Decimal)
        {
            Caption = 'Pago adicional por cuota';
            MinValue = 0;
            AutoFormatType = 1;
            ToolTip = 'Importe opcional que se añade a cada cuota para amortizar capital anticipadamente; adelanta el final del préstamo.';
        }
        field(16; "Entity Name"; Text[100])
        {
            Caption = 'Nombre entidad';
            FieldClass = FlowField;
            CalcFormula = lookup("Bank Account".Name where("No." = field(Entity)));
            Editable = false;
            ToolTip = 'Nombre de la cuenta bancaria de la entidad.';
        }
        field(20; "No. Series"; Code[20])
        {
            Caption = 'Nos. serie';
            TableRelation = "No. Series";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Entity; Entity)
        {
        }
    }

    trigger OnInsert()
    var
        CarteraSetup: Record "Cartera Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            CarteraSetup.Get();
            CarteraSetup.TestField("BeDyn Debt Nos.");
            "No. Series" := CarteraSetup."BeDyn Debt Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnDelete()
    var
        AmortizationLine: Record "BeDyn Debt Amortization Line";
    begin
        AmortizationLine.SetRange("Debt No.", "No.");
        AmortizationLine.DeleteAll();
    end;

    procedure AssistEdit(OldDebt: Record "BeDyn Debt"): Boolean
    var
        CarteraSetup: Record "Cartera Setup";
        NoSeries: Codeunit "No. Series";
    begin
        CarteraSetup.Get();
        CarteraSetup.TestField("BeDyn Debt Nos.");
        if NoSeries.LookupRelatedNoSeries(CarteraSetup."BeDyn Debt Nos.", OldDebt."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;
}
