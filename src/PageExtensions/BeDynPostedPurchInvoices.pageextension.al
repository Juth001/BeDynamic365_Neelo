namespace BeDynamic.CleaningImport;

using Microsoft.Purchases.History;

pageextension 82700 "BeDyn Posted Purch. Invoices" extends "Posted Purchase Invoices"
{
    layout
    {
        addafter("Amount Including VAT")
        {
            field("BeDyn Dimensioned"; Rec."BeDyn Dimensioned")
            {
                ApplicationArea = All;
            }
        }
    }
}
