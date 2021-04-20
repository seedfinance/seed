// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../admin/AdminableInit.sol";
import "./StrategyManagerableInit.sol";
import "./LiquidityableInit.sol";
import "../interface/IMdexChef.sol";
import "../interface/IMdexFactory.sol";
import "../interface/IUniswapV2Router02.sol";
import '../interface/IWETH.sol';
import "../interface/IMdexPair.sol";
import "../libraries/TransferHelper.sol";
import "../interface/IStrategyManager.sol";
import "../libraries/SwapLibrary.sol";

contract LPBuilder is AdminableInit, LiquidityableInit {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public factory;
    address public pair; 
    
    address public token0;
    address public token1;

    constructor() {}

    function initialize(address _adminStore, address _liquidityStore, address _factory, address _pair) public virtual initializer {
        AdminableInit.initializeAdmin(_adminStore); 
        LiquidityableInit.initializeLiquidity(_liquidityStore);
        factory = _factory;
        pair = _pair;
    }

    function tokenToLiquidity(
        address[] calldata tokens,
        uint256[] calldata amountsDesired,
        address to
    ) external returns(uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(tokens.length > 0 && tokens.length <= 2, "must be one token or two");
        require(tokens.length == amountsDesired.length, "tokens and amount length not correspond");
        if(tokens.length == 1) { // only one Token
            require(tokens[0] != address(0),"token0 address mistake");
            (amountA, amountB, liquidity) = swapToLpToken(tokens[0], pair, amountsDesired[0], to);
        }else { // Token + Token
            require(IMdexFactory(factory).getPair(tokens[0], tokens[1]) == pair, "illegal token");
            (amountA, amountB, liquidity) = _addLiquidity(tokens[0], tokens[1], amountsDesired[0], amountsDesired[1], to);
        }
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _getLiquidityAmount(tokenA, tokenB, amountADesired, amountBDesired);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IMdexPair(pair).mint(to);
    }

    function _getLiquidityAmount(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal view returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = IMdexFactory(factory).getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = IMdexFactory(factory).quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = IMdexFactory(factory).quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

}
