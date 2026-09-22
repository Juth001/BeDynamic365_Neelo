namespace Neelo.RecurringInvoicing;

using BeDynamic.PropertyManagement;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;

/// <summary>
/// Staging table used to review/validate CSV lines before posting.
/// </summary>
table 81001 "BeDyn Invoice Import Buffer"
{
    Caption = 'Invoice Import Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(5; "Import Batch Code"; Code[20])
        {
            Caption = 'Import Batch Code';
        }
        field(10; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(15; "Billing Code"; Code[20])
        {
            Caption = 'Billing Code';
        }
        field(20; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(25; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(31; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(32; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(33; "BC Customer No."; Code[20])
        {
            Caption = 'BC ID';
            TableRelation = Customer."No.";
            ValidateTableRelation = false;
        }
        field(35; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
        }
        field(37; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group".Code;
        }
        // ---------------- INDIVIDUALS TEMPLATE ----------------
        // Extra columns of the individuals CSV layout: the property is invoiced as an
        // item, the room as its variant, and the business line is a dimension value
        // stamped on the generated document.
        field(70; "Property Code"; Code[20])
        {
            Caption = 'Property (Item No.)';
            TableRelation = Item."No.";
            ValidateTableRelation = false;
        }
        field(71; "Variant Code"; Code[10])
        {
            Caption = 'Room (Variant Code)';
            TableRelation = "Item Variant".Code where("Item No." = field("Property Code"));
            ValidateTableRelation = false;
        }
        field(72; "Business Line Code"; Code[20])
        {
            Caption = 'Business Line';
        }
        field(73; "Channel Code"; Code[20])
        {
            Caption = 'Channel';
        }
        field(74; "Unit Code"; Code[20])
        {
            Caption = 'Unit';
        }
        field(75; "Deposit No."; Code[20])
        {
            Caption = 'Deposit No.';
            TableRelation = "BeDyn Deposit";
            Editable = false;
        }
        field(40; "Invoice Grouping"; Enum "BeDyn Invoice Grouping")
        {
            Caption = 'Invoice Grouping';
            Editable = false;
        }
        field(45; "Management Bank"; Code[20])
        {
            Caption = 'Management Bank';
            TableRelation = "Bank Account"."No.";
            Editable = false;
        }
        field(50; Status; Enum "BeDyn Buffer Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(55; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            Editable = false;
        }
        field(60; "Posted Document No."; Code[20])
        {
            Caption = 'Generated Document No.';
            Editable = false;
        }
        field(65; "Is Comment"; Boolean)
        {
            Caption = 'Comment Line';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Batch; "Import Batch Code", "Customer No.", "Line No.")
        {
        }
        key(Status; "Import Batch Code", Status)
        {
        }
    }
}
