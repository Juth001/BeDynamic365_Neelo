namespace BeDynamic.PleoImport;

enum 82100 "BeDyn Pleo Expense Type"
{
    Extensible = true;
    Caption = 'Tipo movimiento Pleo';

    value(0; "Card Purchase")
    {
        Caption = 'Compra tarjeta';
    }
    value(1; "Wallet Load")
    {
        Caption = 'Recarga monedero';
    }
    value(2; Cashback)
    {
        Caption = 'Cashback';
    }
    value(9; Other)
    {
        Caption = 'Otro';
    }
}
