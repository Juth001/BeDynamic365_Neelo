namespace Neelo.RecurringInvoicing;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

/// <summary>
/// Per-customer billing configuration. Each row maps a billing code (matched against
/// column 1 of the CSV) and account to the management bank and grouping used when the
/// invoice is generated; the same billing code may appear with different accounts.
/// Replaces the global REC/Extra concept mapping that used to live in the
/// "Recurring Invoicing Setup".
/// </summary>
table 81002 "BeDyn Customer Billing"
{
    Caption = 'Customer Billing';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
            NotBlank = true;
        }
        field(2; "Billing Code"; Code[20])
        {
            Caption = 'Billing Code';
            NotBlank = true;
            TableRelation = "BeDyn Billing Code".Code;
        }
        field(10; "Billing Type"; Enum "BeDyn Billing Type")
        {
            Caption = 'Billing Type';
        }
        field(20; "Management Bank"; Code[20])
        {
            Caption = 'Management Bank';
            TableRelation = "Bank Account"."No.";

            trigger OnValidate()
            var
                BankAccount: Record "Bank Account";
            begin
                if "Management Bank" = '' then
                    exit;
                BankAccount.Get("Management Bank");
                BankAccount.TestField(Blocked, false);
            end;
        }
        field(30; "Invoice Grouping"; Enum "BeDyn Invoice Grouping")
        {
            Caption = 'Invoice Grouping';
        }
        field(40; "Account Type"; Enum "BeDyn Billing Concept Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                if "Account Type" <> xRec."Account Type" then begin
                    "Account No." := '';
                    "Variant Code" := '';
                    "Unit of Measure Code" := '';
                end;
            end;
        }
        field(41; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"."No." where("Account Type" = const(Posting), Blocked = const(false))
            else if ("Account Type" = const(Item)) Item."No." where(Blocked = const(false))
            else if ("Account Type" = const(Resource)) Resource."No." where(Blocked = const(false));

            trigger OnValidate()
            begin
                if "Account No." <> xRec."Account No." then begin
                    "Variant Code" := '';
                    "Unit of Measure Code" := '';
                end;
            end;
        }
        field(42; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Account No."));

            trigger OnValidate()
            begin
                if "Variant Code" <> '' then
                    TestField("Account Type", "Account Type"::Item);
            end;
        }
        field(43; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Default Unit of Measure';
            TableRelation = if ("Account Type" = const(Item)) "Item Unit of Measure".Code where("Item No." = field("Account No."))
            else if ("Account Type" = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("Account No."))
            else
            "Unit of Measure".Code;
        }
        field(50; Deposit; Boolean)
        {
            Caption = 'Deposit';

            trigger OnValidate()
            begin
                // A deposit row posts to a G/L account (the deposit liability account)
                // with the Management Bank as counterpart; no invoice is generated.
                if Deposit then begin
                    TestField(Rental, false);
                    Validate("Account Type", "Account Type"::"G/L Account");
                end;
            end;
        }
        field(51; Rental; Boolean)
        {
            Caption = 'Rental';

            trigger OnValidate()
            begin
                // A rental row invoices normally and, in addition, finds (or creates)
                // the active reservation of the property of each line and stamps it on
                // the generated invoice.
                if Rental then
                    TestField(Deposit, false);
            end;
        }
    }

    keys
    {
        key(PK; "Customer No.", "Billing Code", "Account No.")
        {
            Clustered = true;
        }
    }

    /// <summary>Maps the account type to the standard "Sales Line Type" enum.</summary>
    procedure GetSalesLineType(): Enum "Sales Line Type"
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                exit("Sales Line Type"::"G/L Account");
            "Account Type"::Item:
                exit("Sales Line Type"::Item);
            "Account Type"::Resource:
                exit("Sales Line Type"::Resource);
        end;
    end;
}
