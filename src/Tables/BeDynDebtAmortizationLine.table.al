namespace Neelo.DebtManagement;

// Cuadro de amortización de una deuda: una línea por cuota, con su desglose de
// principal e intereses. El total de la cuota se calcula solo. La marca Pagada
// saca la cuota de los importes pendientes de la deuda.
table 81101 "BeDyn Debt Amortization Line"
{
    Caption = 'Línea amortización deuda';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Debt No."; Code[20])
        {
            Caption = 'Nº deuda';
            TableRelation = "BeDyn Debt";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        field(3; "Amortization Date"; Date)
        {
            Caption = 'Fecha amortización';
            ToolTip = 'Fecha de vencimiento de la cuota.';
        }
        field(4; "Principal Amount"; Decimal)
        {
            Caption = 'Importe principal';
            MinValue = 0;
            AutoFormatType = 1;
            ToolTip = 'Parte de la cuota que amortiza capital.';

            trigger OnValidate()
            begin
                UpdateTotal();
            end;
        }
        field(5; "Interest Amount"; Decimal)
        {
            Caption = 'Intereses';
            MinValue = 0;
            AutoFormatType = 1;
            ToolTip = 'Parte de la cuota que corresponde a intereses.';

            trigger OnValidate()
            begin
                UpdateTotal();
            end;
        }
        field(6; "Total Amount"; Decimal)
        {
            Caption = 'Total cuota';
            Editable = false;
            AutoFormatType = 1;
            ToolTip = 'Total de la cuota: principal más intereses.';
        }
        field(7; Paid; Boolean)
        {
            Caption = 'Pagada';
            ToolTip = 'Marca la cuota como pagada: deja de contar en el capital, intereses y total pendientes de la deuda.';
        }
    }

    keys
    {
        key(PK; "Debt No.", "Line No.")
        {
            Clustered = true;
        }
        key(DateKey; "Debt No.", "Amortization Date")
        {
        }
        key(Pending; "Debt No.", Paid)
        {
            SumIndexFields = "Principal Amount", "Interest Amount", "Total Amount";
        }
    }

    local procedure UpdateTotal()
    begin
        "Total Amount" := "Principal Amount" + "Interest Amount";
    end;
}
