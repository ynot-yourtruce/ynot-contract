pragma solidity >0.8.0;
import "./interface/IERC20.sol";
import "./interface/IFactory.sol";
import "./PairPool.sol";

contract Router{

    IYNOTFactory public factory;

    constructor(address _factory_address){
        factory = IYNOTFactory(_factory_address);
    }

    /** Perform a swap */
    function swap(address[] memory path, uint256 [] memory amount, address _to) internal{

        for(uint256 i=0; i< path.length; i++){

            address pool_address = factory.getPool(path[i], path[i+1]);

            address to = i < path.length - 2 ? factory.getPool(path[i+1], path[i+2]) : _to;
            PairPool pair = PairPool(pool_address);
            pair.swapToken(amount[i], to);
        }
    }


    function swapTokensForExactTokens(address[] memory path, uint256 amount, uint256 minAmountOut, address _to) internal returns(uint256){

        uint256[] memory amountOut = getAmountsOut(path, amount);
        require(amountOut[amountOut.length - 1] >= minAmountOut);
        swap(path, amountOut, _to);
        return amountOut[amountOut.length - 1];
    }

    function swapExactTokensForTokens(address[] memory path, uint256 amount, uint256 minAmountIn, address _to) internal returns(uint256){

        uint256[] memory amountIn = getAmountsIn(path, amount);
        require(amountIn[amountIn.length - 1] <= minAmountIn);
        swap(path, amountIn, _to);
        return amountIn[amountIn.length - 1];
    }


    /** Get amount out through a path */
    function getAmountsOut(address[] memory path, uint256 amountIn) public returns(uint256[] memory amounts){

        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            PairPool pairPool = PairPool(factory.getPool(path[i], path[i+1]));
            amounts[i + 1] = pairPool.getAmountOut(amounts[i]);
        }
    }

    /** Get amount in through a path */
    function getAmountsIn(address[] memory path, uint256 amountIn) public returns(uint256[] memory amounts){

        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            PairPool pairPool = PairPool(factory.getPool(path[i], path[i+1]));
            amounts[i + 1] = pairPool.getAmountIn(amounts[i]);
        }
    }

}