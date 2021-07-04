pragma solidity >0.8.0;

interface IYNOTFactory{

    /** Create a pair */
    function createAPair(address _tokenA, address _tokenB, uint256 _slippage, uint256 _minAmount, uint256 _maxAmount) external view;


    /** Get pools */
    function getPool(address _tokenA, address _tokenB) external view returns (address);

}