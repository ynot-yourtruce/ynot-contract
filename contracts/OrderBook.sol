pragma solidity >0.8.0;
pragma experimental ABIEncoderV2;
import "./interface/IERC20.sol";
import "./interface/IPairPool.sol";

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
        tokenA = _tokenB;
    }

    function addOrder(address _token, uint256 amount) public{

        uint256 rest_amount = amount;

        address token1 = _token == tokenA ? tokenB : tokenA;

        uint256 balance = IERC20(token1).balanceOf(address(this));

        if(balance > 0){
            fillOrder(_token, amount, balance, msg.sender);
        }else{
            addToOrderBook(msg.sender, amount);
        }

        if(rest_amount > 0){
            IERC20(_token).transferFrom(msg.sender, address(this), rest_amount);
        }
    }


    function addToOrderBook(address owner, uint256 amount) private{
        end++;
        offers[end] = OfferStruct(owner, amount, amount, end, end+ 1, end - 1);

        if (end - 1 != 0) {
            offers[end - 1].next = end;
        }
    }

    function fillOrder(address token, uint256 amount, uint256 balance, address owner) private {

        IPairPool pool = IPairPool(pairPool);
        address _tokenB;
        uint reserve0;
        uint reserve1;
        { //reduce stack too deep
            (uint reserveA, uint reserveB) = IPairPool(pairPool).getReserve();

            (_tokenB, reserve0, reserve1) = token == tokenA ? (tokenB,  reserveA, reserveB) : (tokenA, reserveB, reserveA);
        }


        uint amountBOptimal = pool.quote(amount, reserve0, reserve1);

        uint256 amountB = amountBOptimal > balance ? balance : amountBOptimal;
        
        
        LoopData memory local = LoopData(amountB, amount, 0, 0);
        
        for(uint i = start; local.remainingB > 0; i++){

            OfferStruct memory selected_offer = offers[i];

            uint256 _amount = (local.remainingB > selected_offer.balance)? selected_offer.balance : selected_offer.balance - local.remainingB;

            uint256 amountA =  pool.quote(_amount, reserve1, reserve0);

            local.remainingB -= _amount;
            local.remainingA -= amountA;
            
            IERC20(token).transferFrom(owner, address(pool), amountA);
            IERC20(_tokenB).transfer(address(pool), _amount);
            pool.mint(owner, selected_offer.owner);

            offers[i].balance = offers[i].balance - local.remainingB;
            local.lastBal = offers[i].balance;
            local.lastId = i;
        }

        // move the cursor to 
        if(local.lastBal == 0){
            start = local.lastId+1;
        }else{
            start = local.lastId;
        }

        
        if(local.remainingA > 0){
            addToOrderBook(owner, local.remainingA);
        }

    }
}