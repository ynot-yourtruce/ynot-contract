// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "./PairPool.sol";

contract YNOTFactory{


    address public owner;
    mapping(address => mapping(address => address)) public pairs;
    mapping(address => address) public liquidityMinters;
    address[] public pools;
    address public last_pool;

    constructor(){
        owner = msg.sender;
    }

    /** Create a pair */
    function createAPair(address _tokenA, address _tokenB) public{
        require(msg.sender == owner, "Only owner can do");
        require(pairs[_tokenA][_tokenB] == address(0), "Already exists");

        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        PairPool new_pair = new PairPool(token0, token1, msg.sender);

        pairs[token1][token0] = address(new_pair);
        pairs[token0][token1] = address(new_pair);

        last_pool = address(new_pair);

        pools.push(address(new_pair));

        // LiquidityMinter new_minter = new LiquidityMinter(address(new_pair), _tokenA, _tokenB);
        
        // liquidityMinters[address(new_pair)] = address(new_minter);
    }

    function getLastPool() public view returns(address){
        return last_pool;
    }


    /** Get pools */
    function getPool(address _tokenA, address _tokenB) public view returns(address){
        return pairs[_tokenA][_tokenB];
    }

    /** Get all pools */
    function getAllPools() public view returns(address[] memory){
        return pools;
    }

    /** Change Owner */
    function changeOwner(address _owner) public{
        require(msg.sender == owner, "Only owner can change");
        owner = _owner;
    }

    function addLiquidityMinter(address pair, address liquidityMinter) public{
        require(msg.sender == owner, "Only owner can do");
        liquidityMinters[pair] = liquidityMinter;
    }
}