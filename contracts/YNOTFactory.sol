// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "./PairPool.sol";

contract YNOTFactory{


    address public owner;
    mapping(address => mapping(address => address)) public pairs;
    mapping(address => address) public liquidityMinters;

    constructor(){
        owner = msg.sender;
    }

    /** Create a pair */
    function createAPair(address _tokenA, address _tokenB) public returns(address){
        require(msg.sender == owner, "Only owner can do");
        require(pairs[_tokenA][_tokenB] == address(0), "Already exists");

        PairPool new_pair = new PairPool(_tokenA, _tokenB, msg.sender);

        pairs[_tokenA][_tokenB] = address(new_pair);
        pairs[_tokenB][_tokenA] = address(new_pair);

        return address(new_pair);

        // LiquidityMinter new_minter = new LiquidityMinter(address(new_pair), _tokenA, _tokenB);
        
        // liquidityMinters[address(new_pair)] = address(new_minter);
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

    function addLiquidityMinter(address pair, address liquidityMinter) public{
        require(msg.sender == owner, "Only owner can do");
        liquidityMinters[pair] = liquidityMinter;
    }
}