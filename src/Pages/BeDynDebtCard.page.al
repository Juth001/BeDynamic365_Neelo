namespace Neelo.DebtManagement;

page 81101 "BeDyn Debt Card"
{
    PageType = Card;
    SourceTable = "BeDyn Debt";
    Caption = 'Deuda';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                }
                field(Entity; Rec.Entity)
                {
                }
                field("Entity Name"; Rec."Entity Name")
                {
                }
                field("Start Date"; Rec."Start Date")
                {
                }
                field("End Date"; Rec."End Date")
                {
                }
                field(Capital; Rec.Capital)
                {
                }
                field("Interest Rate %"; Rec."Interest Rate %")
                {
                }
                field("No. of Payments"; Rec."No. of Payments")
                {
                }
                field("Payments per Year"; Rec."Payments per Year")
                {
                }
                field("Additional Payment"; Rec."Additional Payment")
                {
                }
                field("No. of Installments"; Rec."No. of Installments")
                {
                }
            }
            part(AmortizationLines; "BeDyn Debt Amortization")
            {
                Caption = 'Cuadro de amortización';
                SubPageLink = "Debt No." = field("No.");
                UpdatePropagation = Both;
            }
            group(PendingAmounts)
            {
                Caption = 'Importes pendientes';

                field("Pending Principal"; Rec."Pending Principal")
                {
                }
                field("Pending Interest"; Rec."Pending Interest")
                {
                }
                field("Pending Total"; Rec."Pending Total")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CalcSchedule)
            {
                ApplicationArea = All;
                Caption = 'Calcular cuotas';
                Image = Calculate;
                ToolTip = 'Genera el cuadro de amortización por el sistema francés (cuota constante) a partir del capital, el tipo de interés, el nº de pagos, los pagos por año y el pago adicional opcional. La primera cuota vence en la fecha de la deuda.';

                trigger OnAction()
                var
                    AmortizationCalc: Codeunit "BeDyn Debt Amortization Calc";
                begin
                    AmortizationCalc.GenerateSchedule(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(CalcSchedule_Promoted; CalcSchedule)
                {
                }
            }
        }
    }
}
