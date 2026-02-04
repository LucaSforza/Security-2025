import "./Taxpayer.sol";
import "./Lottery.sol";

contract FactoryTaxpayer {
    address immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner");
        _;
    }
    mapping(address => bool) private taxpayers;
    Lottery immutable l;

    constructor(address _owner) {
        owner = _owner;
        l = new Lottery(this, _owner);
    }

    function createTaxpayer(address p1, address p2, uint8 day, uint8 month, uint16 year)
        public
        onlyOwner
        returns (address)
    {
        require(taxpayers[p1] || p1 == address(0));
        require(taxpayers[p2] || p2 == address(0));
        // TODO: verifica che la data abbia senso
        Taxpayer t = new Taxpayer(this, p1, p2, day, month, year);
        taxpayers[address(t)] = true;
        return address(t);
    }

    function isTaxpayer(address t) public view returns (bool) {
        return taxpayers[t];
    }

    function isLottery(address lot) public view returns (bool) {
        return address(l) == lot;
    }

    function getLottery() public view returns (address) {
        return address(l);
    }
}
