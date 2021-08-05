// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "./LiquidityMinter.sol";
import "./interface/IFactory.sol";

contract Genesis{

    IYNOTFactory public factory;

    function createNewPair(address _tokenA, address _tokenB) public{
        
        factory.createAPair(_tokenA, _tokenB);
        
        address pool_addr = factory.getLastPool();
        
        LiquidityMinter new_minter = new LiquidityMinter(address(pool_addr), _tokenA, _tokenB);

        factory.addLiquidityMinter(pool_addr, address(new_minter));
    }

    function setFactory(address new_factory) public{
        factory = IYNOTFactory(new_factory);
    }
}