// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "./lib/SafeMath.sol";
import "./lib/Math.sol";
import './interface/IERC20.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PairPool is ERC721{

    using SafeMath  for uint256;
    
    address public tokenA;
    address public tokenB;
    address public owner;

    uint256 public reserveIn;
    uint256 public reserveOut;

    bool public is_active;

    mapping (uint256 => uint256) public particles;
    mapping (uint256 => address) public particlesElement;
    mapping (uint256 => uint256) public liqstake;
    uint256 public nftId;

    uint256 public totalSupply;
    

    constructor(address _tokenA, address _tokenB, address _owner) ERC721("QuantumParticles", "QP"){
        tokenA = _tokenA;
        tokenB = _tokenB;
        owner = _owner;
    }
    
    /** Allow Market takers to swap tokens */
    function swapToken(uint256 amount, address reciver) public returns(uint256){
        // take TokenB give TokenA

        uint256 amountAfterFee = getAmountOut(amount);
        
        IERC20(tokenB).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenA).transfer(reciver, amountAfterFee);
        
        return amountAfterFee;
    }

    /** Get estimated amount of token afer swap */
    function getAmountOut(uint amountIn) public view returns(uint256 amountOut){

        require(amountIn > 0, 'amount must be greater then zero');

        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
        
    }

    function getAmountIn(uint amountOut) public view returns(uint256 amountIn){
        require(amountOut > 0, 'amount must be greater then zero');

        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }


    function changeOwner(address _owner) public{
        require(msg.sender == owner, "Only owner can change");
        owner = _owner;
    }

    function getReserve() public view returns(uint256, uint256){
        return (reserveIn, reserveOut);
    }

    function quote(uint amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint amountB) {
        require(amountA > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }


    function mint(address one, address two) public{

        uint balance0 = IERC20(tokenA).balanceOf(address(this));
        uint balance1 = IERC20(tokenB).balanceOf(address(this));

        uint amount0 = balance0.sub(reserveIn);
        uint amount1 = balance1.sub(reserveOut);

        uint256 liquidity = 0;

        if(totalSupply == 0){
            liquidity = Math.sqrt(amount0.mul(amount1));
        }else{
            liquidity = Math.min(amount0.mul(totalSupply) / reserveIn, amount1.mul(totalSupply) / reserveOut);
        }
        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');


        mintPair(one, two, liquidity);

        reserveIn = balance0;
        reserveOut = balance1;
    }

    function quantumEntangle(uint id0, uint id1) private{
        particles[id0] = id1;
        particles[id1] = id0;

        particlesElement[id0] = tokenA;
        particlesElement[id1] = tokenB;
    }

    function mintPair(address usera, address userb, uint liquidity) private{

        nftId++;
        uint256 id0 = nftId;
        _mint(usera, id0);

        nftId++;
        uint256 id1 = nftId;
        _mint(userb, id1);

        liqstake[id0] = liquidity;
        liqstake[id1] = liquidity;

        totalSupply += liquidity;

        quantumEntangle(id0,  id1);
    }

    function burnPair(uint256 tokenId) private{

        totalSupply -= liqstake[tokenId];
        _burn(tokenId);
        _burn(particles[tokenId]);
    }


    function removeLiquidity(uint256 tokenId) public{

        (address token0, address token1) = particlesElement[tokenId] == tokenA ? (tokenA, tokenB) : (tokenB, tokenA);

        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = liqstake[tokenId].mul(balance0) / totalSupply;
        uint256 amount1 = liqstake[tokenId].mul(balance1) / totalSupply;
        

        IERC20(token0).transfer(ownerOf(tokenId), amount0);
        IERC20(token1).transfer(ownerOf(particles[tokenId]), amount1);

        burnPair(tokenId);
    }
}