// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IPairPool{

    function mint(address one, address two) external pure;


    function quote(uint amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint amountB);

    function getReserve() external pure returns(uint256, uint256);

}