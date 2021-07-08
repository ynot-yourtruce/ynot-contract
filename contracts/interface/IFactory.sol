// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IYNOTFactory{


    /** Get pools */
    function getPool(address _tokenA, address _tokenB) external view returns (address);

    function createAPair(address _tokenA, address _tokenB) external returns(address);

    function addLiquidityMinter(address pair, address liquidityMinter) external;
}