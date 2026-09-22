namespace Neelo.RecurringInvoicing;

/// <summary>
/// Master list of billing codes used in the customer billing configuration and matched
/// against column 1 of the import CSV.
/// </summary>
table 81003 "BeDyn Billing Code"
{
    Caption = 'Billing Code';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Billing Codes";
    DrillDownPageId = "BeDyn Billing Codes";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }
}
