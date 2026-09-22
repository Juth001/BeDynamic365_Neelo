namespace Neelo.RecurringInvoicing;

using Microsoft.Finance.Dimension;

/// <summary>
/// Singleton setup for recurring / extra invoicing. The per-billing-code account mapping
/// now lives on the customer, in table "Customer Billing".
/// </summary>
table 81000 "BeDyn Recurring Inv. Setup"
{
    Caption = 'Recurring Invoicing Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(30; "CSV Separator"; Code[1])
        {
            Caption = 'CSV Separator';
            InitValue = ';';
        }
        field(31; "Has Header"; Boolean)
        {
            Caption = 'Has Header';
        }
        field(40; "NIF Source"; Enum "BeDyn NIF Source")
        {
            Caption = 'Tax ID Source';
        }
        field(50; "Default Posting"; Boolean)
        {
            Caption = 'Post Automatically';
            InitValue = true;
        }
        field(60; Active; Boolean)
        {
            Caption = 'Active';
        }
        field(70; "Insert Comments"; Boolean)
        {
            Caption = 'Insert Comments';
        }
        field(80; "Ignore Comments"; Boolean)
        {
            Caption = 'Ignore Comments';
        }
        field(90; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(100; "Business Line Dim. Code"; Code[20])
        {
            Caption = 'Business Line Dimension Code';
            TableRelation = Dimension.Code;
        }
        field(110; "Channel Dim. Code"; Code[20])
        {
            Caption = 'Channel Dimension Code';
            TableRelation = Dimension.Code;
        }
        field(120; "Unit Dim. Code"; Code[20])
        {
            Caption = 'Unit Dimension Code';
            TableRelation = Dimension.Code;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>Gets (creating if missing) the singleton setup record.</summary>
    procedure GetSetup()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
