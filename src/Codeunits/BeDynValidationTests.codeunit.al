namespace Neelo.RecurringInvoicing;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Sales.Customer;

/// <summary>
/// Unit tests for the buffer validation.
///
/// NOTE: the tests use custom assertions (no "Library Assert") so the main app does
/// not require extra dependencies. To RUN them the Test Toolkit must be installed.
/// For AppSource, move this codeunit to a separate test app that depends on this
/// extension (Subtype = Test objects are not allowed in the main AppSource app).
/// </summary>
codeunit 81021 "BeDyn Validation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NextSuffix: Integer;

    [Test]
    procedure SetupInactiveBlocksValidation()
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        ValidationMgt: Codeunit "BeDyn Validation Mgt.";
    begin
        // [GIVEN] Inactive setup and a batch with one line
        InitSetup(false);
        CreateBufferLine(Buffer, 'TESTBATCH', '', 100);

        // [WHEN] The batch is validated / [THEN] an error is raised because setup is inactive
        asserterror ValidationMgt.ValidateBatch('TESTBATCH');
        AssertTrue(GetLastErrorText() <> '', 'An error should be raised when the setup is inactive.');
    end;

    [Test]
    procedure CustomerNotFoundMarksError()
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        ValidationMgt: Codeunit "BeDyn Validation Mgt.";
    begin
        // [GIVEN] Active setup and a line with a non-existent Tax ID
        InitSetup(true);
        CreateBufferLine(Buffer, 'TESTBATCH', 'TAXID-MISSING-XYZ', 100);

        // [WHEN] The line is validated
        ValidationMgt.ValidateLine(Buffer);

        // [THEN] It ends in Error status
        AssertTrue(Buffer.Status = Buffer.Status::Error, 'It should be flagged Error because the customer is not found.');
    end;

    [Test]
    procedure AmbiguousNIFMarksError()
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        ValidationMgt: Codeunit "BeDyn Validation Mgt.";
        BankNo: Code[20];
        NIF: Text[20];
    begin
        // [GIVEN] Two customers with the same Tax ID
        BankNo := CreateBankAccount();
        InitSetup(true);
        NIF := 'B12345678';
        CreateCustomerFull(NIF, BankNo);
        CreateCustomerFull(NIF, BankNo);
        CreateBufferLine(Buffer, 'TESTBATCH', NIF, 100);

        // [WHEN] The line is validated
        ValidationMgt.ValidateLine(Buffer);

        // [THEN] Error because of ambiguous Tax ID
        AssertTrue(Buffer.Status = Buffer.Status::Error, 'It should be flagged Error because of ambiguous Tax ID.');
    end;

    [Test]
    procedure MissingBillingCodeMarksError()
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        ValidationMgt: Codeunit "BeDyn Validation Mgt.";
        BankNo: Code[20];
        NIF: Text[20];
    begin
        // [GIVEN] A valid customer, but the CSV billing code has no configuration
        BankNo := CreateBankAccount();
        InitSetup(true);
        NIF := 'C11111111';
        CreateCustomerFull(NIF, BankNo);
        CreateBufferLine(Buffer, 'TESTBATCH', NIF, 100);
        Buffer."Billing Code" := 'DOES-NOT-EXIST';
        Buffer.Modify();

        // [WHEN] The line is validated
        ValidationMgt.ValidateLine(Buffer);

        // [THEN] Error because the customer has no such billing configuration
        AssertTrue(Buffer.Status = Buffer.Status::Error, 'It should be flagged Error because the billing code is not configured.');
    end;

    [Test]
    procedure ValidCustomerCopiesBankAndGrouping()
    var
        Buffer: Record "BeDyn Invoice Import Buffer";
        ValidationMgt: Codeunit "BeDyn Validation Mgt.";
        BankNo: Code[20];
        NIF: Text[20];
    begin
        // [GIVEN] A valid customer with a billing configuration (bank + grouping)
        BankNo := CreateBankAccount();
        InitSetup(true);
        NIF := 'A87654321';
        CreateCustomerFull(NIF, BankNo);
        CreateBufferLine(Buffer, 'TESTBATCH', NIF, 250);

        // [WHEN] The line is validated
        ValidationMgt.ValidateLine(Buffer);

        // [THEN] It is Validated and copies the bank/grouping from the billing configuration
        AssertTrue(Buffer.Status = Buffer.Status::Validated, 'It should be Validated.');
        AssertTrue(Buffer."Management Bank" = BankNo, 'It should copy the Management Bank.');
    end;

    // --- Helpers ---

    local procedure InitSetup(Active: Boolean)
    var
        Setup: Record "BeDyn Recurring Inv. Setup";
    begin
        Setup.GetSetup();
        Setup.Active := Active;
        Setup."NIF Source" := Setup."NIF Source"::"VAT Registration No.";
        Setup."CSV Separator" := ';';
        Setup.Modify();
    end;

    local procedure CreateBufferLine(var Buffer: Record "BeDyn Invoice Import Buffer"; BatchCode: Code[20]; NIF: Text[20]; LineAmount: Decimal)
    begin
        Buffer.Init();
        Buffer."Import Batch Code" := BatchCode;
        Buffer."Line No." := 1;
        Buffer."Billing Code" := 'REC';
        Buffer."VAT Registration No." := NIF;
        Buffer.Description := 'Test';
        Buffer.Amount := LineAmount;
        Buffer.Status := Buffer.Status::Pending;
        Buffer.Insert(true);
    end;

    local procedure CreateCustomerFull(NIF: Text[20]; BankNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := NextNo('CUST');
        Customer."VAT Registration No." := NIF;
        Customer."Customer Posting Group" := EnsureCustomerPostingGroup();
        Customer.Insert();
        CreateBilling(Customer."No.", BankNo);
        exit(Customer."No.");
    end;

    local procedure CreateBilling(CustomerNo: Code[20]; BankNo: Code[20])
    var
        CustomerBilling: Record "BeDyn Customer Billing";
    begin
        CustomerBilling.Init();
        CustomerBilling."Customer No." := CustomerNo;
        CustomerBilling."Billing Code" := 'REC';
        CustomerBilling."Billing Type" := CustomerBilling."Billing Type"::Recurring;
        CustomerBilling."Management Bank" := BankNo;
        CustomerBilling."Invoice Grouping" := CustomerBilling."Invoice Grouping"::Grouped;
        CustomerBilling."Account Type" := CustomerBilling."Account Type"::"G/L Account";
        CustomerBilling."Account No." := CreatePostingGLAccount();
        CustomerBilling.Insert();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Init();
        BankAccount."No." := NextNo('BNK');
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure EnsureCustomerPostingGroup(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if CustomerPostingGroup.FindFirst() then
            exit(CustomerPostingGroup.Code);
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Code := 'TESTGRP';
        CustomerPostingGroup.Insert();
        exit(CustomerPostingGroup.Code);
    end;

    local procedure CreatePostingGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := NextNo('GL');
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure NextNo(Prefix: Text): Code[20]
    begin
        NextSuffix += 1;
        exit(CopyStr(Prefix + Format(NextSuffix), 1, 20));
    end;

    local procedure AssertTrue(Condition: Boolean; Msg: Text)
    begin
        if not Condition then
            Error(Msg);
    end;
}
