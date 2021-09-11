// File: contracts/interface/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interface/IPairPool.sol




interface IPairPool{

    function mint(address one, address two) external;


    function quote(uint amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint amountB);

    function getReserve() external pure returns(uint256, uint256);

}

// File: contracts/OrderBook.sol


pragma experimental ABIEncoderV2;



contract LiquidityMinter {
    
    struct OfferStruct {
        address owner;
        uint256 balance;
        uint256 total;
        uint256 id;
        uint256 next;
        uint256 prev;
    }

    struct LoopData{
        uint256 remainingB;
        uint256 remainingA;
        uint256 lastBal;
        uint256 lastId;
    }


    mapping (uint256 => OfferStruct) public offers;

    address public pairPool;
    address public tokenA;
    address public tokenB;

    uint256 public start;
    uint256 public end;


    constructor(address _pairPool, address _tokenA, address _tokenB) {
        start = 1;

        pairPool = _pairPool;
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addOrder(address _token, uint256 amount) public{

        address token1 = _token == tokenA ? tokenB : tokenA;

        uint256 balance = IERC20(token1).balanceOf(address(this));

        if(balance > 0){
            fillOrder(_token, amount, balance, msg.sender);
        }else{
            addToOrderBook(_token, msg.sender, amount);
        }

    }


    function addToOrderBook(address token, address owner, uint256 amount) private{
        end++;
        offers[end] = OfferStruct(owner, amount, amount, end, end+ 1, end - 1);

        IERC20(token).transferFrom(owner, address(this), amount);

        if (end - 1 != 0) {
            offers[end - 1].next = end;
        }
    }

    function fillOrder(address token, uint256 amount,  uint256 balance, address owner) private {
        
        IPairPool pool = IPairPool(pairPool);
        address _tokenB;
        uint reserve0;
        uint reserve1;
        
        { //reduce stack too deep
            (uint reserveA, uint reserveB) = IPairPool(pairPool).getReserve();

            (_tokenB, reserve0, reserve1) = token == tokenA ? (tokenB,  reserveA, reserveB) : (tokenA, reserveB, reserveA);
        }
        
        LoopData memory local = LoopData(balance, amount, 0, 0);
        
        for(uint i = start; local.remainingB > 0 && local.remainingA > 0 ; i++){
            
            OfferStruct memory selected_offer = offers[i];

            uint256 amountB = selected_offer.balance;

            uint256 amountA =  pool.quote(amountB, reserve1, reserve0);
            
            if(amountA > local.remainingA){
                amountA = local.remainingA;
                amountB = pool.quote(amountA, reserve0, reserve1);
            }
            
            
            local = LoopData(local.remainingB - amountB, local.remainingA - amountA, 0, i);
            
            require(amountA <= amount, "Amount A is too much");
            require(amountB <= balance, "Balance is less bro");
            IERC20(token).transferFrom(owner, address(pool), amountA);
            IERC20(_tokenB).transfer(address(pool), amountB);
            
            if(token == tokenA){
                pool.mint(owner, selected_offer.owner);
            }else{
                pool.mint(selected_offer.owner, owner);
            }
        }
        
    }
}
