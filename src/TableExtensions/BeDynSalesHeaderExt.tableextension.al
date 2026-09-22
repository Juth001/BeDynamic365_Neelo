namespace BeDynamic.PropertyManagement;

using Microsoft.Sales.Document;

tableextension 82500 "BeDyn Sales Header Ext." extends "Sales Header"
{
    fields
    {
        field(82500; "Reservation No."; Code[20])
        {
            Caption = 'Nº reserva';
            TableRelation = "BeDyn Reservation";
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(82501; "Reservation Billed Until"; Date)
        {
            Caption = 'Reserva facturada hasta';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(82502; "Deposit No."; Code[20])
        {
            Caption = 'Nº fianza';
            TableRelation = "BeDyn Deposit";
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
