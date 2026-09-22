namespace Neelo.RecurringInvoicing;

using BeDynamic.PropertyManagement;
using Microsoft.Sales.Customer;

/// <summary>
/// Archive of processed invoice import buffer lines. Field numbers mirror the buffer
/// table so lines are moved with TransferFields; the archive only adds when and by
/// whom the line was archived.
/// </summary>
table 81004 "BeDyn Invoice Import Archive"
{
    Caption = 'Invoice Import Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
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
        }
        field(35; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
        }
        field(37; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
        }
        field(40; "Invoice Grouping"; Enum "BeDyn Invoice Grouping")
        {
            Caption = 'Invoice Grouping';
        }
        field(45; "Management Bank"; Code[20])
        {
            Caption = 'Management Bank';
        }
        field(50; Status; Enum "BeDyn Buffer Status")
        {
            Caption = 'Status';
        }
        field(55; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(60; "Posted Document No."; Code[20])
        {
            Caption = 'Generated Document No.';
        }
        field(65; "Is Comment"; Boolean)
        {
            Caption = 'Comment Line';
        }
        field(70; "Property Code"; Code[20])
        {
            Caption = 'Property (Item No.)';
        }
        field(71; "Variant Code"; Code[10])
        {
            Caption = 'Room (Variant Code)';
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
        }
        field(90; "Archived At"; DateTime)
        {
            Caption = 'Archived At';
        }
        field(91; "Archived By"; Code[50])
        {
            Caption = 'Archived By';
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
    }
}
