pragma solidity >0.8.0;
import "./PairPool.sol";
import "./LiquidityMinter.sol";

contract YNOTFactory{

    struct PoolStruct{
        address tokenA;
        address tokenB;
        address pool;
        uint256 slippage;
        uint256 minAmount;
        uint256 maxAmount;
    }

    address public owner;
    mapping(address => mapping(address => address)) public pairs;

    constructor(){
        owner = msg.sender;
    }

    /** Create a pair */
    function createAPair(address _tokenA, address _tokenB) public {
        require(pairs[_tokenA][_tokenB] == address(0), "Already exists");

        PairPool new_pair = new PairPool(_tokenA, _tokenB, msg.sender);

        pairs[_tokenA][_tokenB] = address(new_pair);
        pairs[_tokenB][_tokenA] = address(new_pair);

        LiquidityMinter new_minter = new LiquidityMinter(address(new_pair), _tokenA, _tokenB, address(this));
        
    }


    /** Get pools */
    function getPool(address _tokenA, address _tokenB) public view returns(address){
        return pairs[_tokenA][_tokenB];
    }

    /** Change Owner */
    function changeOwner(address _owner) public{
        require(msg.sender == owner, "Only owner can change");
        owner = _owner;
    }
}