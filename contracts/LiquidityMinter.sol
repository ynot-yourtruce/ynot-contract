// SPDX-License-Identifier: MIT
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


    mapping ( address => mapping(uint256 => OfferStruct)) public offers;

    address public pairPool;
    address public tokenA;
    address public tokenB;

    mapping (address => uint256) public start;
    mapping (address => uint256) public end;


    constructor(address _pairPool, address _tokenA, address _tokenB) {
        start[tokenA] = 1;
        end[tokenA] = 0;

        start[tokenB] = 1;
        end[tokenB] = 0;

        pairPool = _pairPool;
        tokenA = _tokenA;
        tokenA = _tokenB;
    }


    function create(address token, uint256 amount) public {
        end[token]++;

        offers[token][end[token]] = OfferStruct(msg.sender, amount, amount, end[token], end [token]+ 1, end[token] - 1);

        if (end[token] - 1 != 0) {
            offers[token][end[token] - 1].next = end[token];
        }
    }


    function read(address token, uint256 _start, uint256 count) public view returns (OfferStruct[] memory){
        uint256 next = _start;

        OfferStruct[] memory offer_list = new OfferStruct[](count);

        for (uint256 i = 0; i < count; i++) {

            offer_list[i] = offers[token][next];
            next = offers[token][next].next;

            if (next > end[token] || next == 0) {
                break;
            }
        }

        return offer_list;
    }

    
    function deleteOffer(address token, uint256 id) public {

        require(msg.sender == offers[token][id].owner);

        if (offers[token][id].next <= end[token]) {
            offers[token][offers[token][id].next].prev = offers[token][id].prev;
        }

        if (offers[token][id].prev >= start[token]) {
            offers[token][offers[token][id].prev].next = offers[token][id].next;
        }

        if (id == end[token]) {
            end[token] = offers[token][id].prev;
        } else if (id == start[token]) {
            start[token] = offers[token][id].next;
        }

        delete offers[token][id];

    }

    
    function matchPool(uint amount, address token, uint256 id) public {

        OfferStruct memory selected_offer;

        IPairPool pool = IPairPool(pairPool);
        (uint reserveA, uint reserveB) = IPairPool(pairPool).getReserve();

        if(token == tokenA){
            selected_offer = offers[tokenB][id];

            uint amountBOptimal = pool.quote(amount, reserveA, reserveB);

            require(amountBOptimal <= selected_offer.balance, "Can not match");
            IERC20(tokenB).transfer(address(pool), amount);
            IERC20(tokenA).transferFrom(msg.sender, address(pool), amount);
            pool.mint(selected_offer.owner, msg.sender);
        }else{
            selected_offer = offers[tokenA][id];

            uint amountBOptimal = pool.quote(amount, reserveB, reserveA);

            require(amountBOptimal <= selected_offer.balance, "Can not match");
            IERC20(tokenA).transfer(address(pool), amount);
            IERC20(tokenB).transferFrom(msg.sender, address(pool), amount);
            pool.mint(msg.sender, selected_offer.owner);
        }
    }



}
