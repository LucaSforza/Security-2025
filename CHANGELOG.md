# 25 Nov 2025

Creato progetto foundry.

Fatto forge fmt e sistemi import.

`
note[mixed-case-variable]: mutable variables should use mixedCase
  --> /Users/lucasforza/Programming/security-25-mag/src/Taxpayer.sol:26:13
   |
26 |     uint256 tax_allowance;
   |             -------------
   |
   = help: https://book.getfoundry.sh/reference/forge/forge-lint#mixed-case-variable

note[mixed-case-variable]: mutable variables should use mixedCase
  --> /Users/lucasforza/Programming/security-25-mag/src/Taxpayer.sol:45:28
   |
45 |     function marry(address new_spouse) public {
   |                            ----------
   |
   = help: https://book.getfoundry.sh/reference/forge/forge-lint#mixed-case-variable
`

Risolte queste note sullo stile.

## Question 

```Solidity
function haveBirthday() public {
    age++;
}
```

This code is wild. Can we modify anything we want in the project.?

## Da mettere nella relazione

Utilizzerò un approccio Agile. Per ogni parte del progetto farò analisi e poi progettazione. Quando passo alla fase successiva torno all'analisi.

## Altre modifiche

```Solidity
interface ILotteryReceiver {
    function joinLottery(address lot, uint256 r) external;
    function revealLottery(address lot, uint256 r) external;
}

interface ITaxpayer is ILotteryReceiver {
    function marry(address newSpouse) external;
    function divorce() external;
    function transferAllowance(uint256 change) external;
    function age() external view returns (uint256 _age);
    function setTaxAllowance(uint256 ta) external;
}
```

Taxpayer è un'interfaccia cosi da poter implementare ERC165.

tolta la funzione `haveBirthday` e aggiunto attributo birthday public.

