// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import './SwapableInit.sol';
import '../libraries/UniswapV2Library.sol';
import '../libraries/TransferHelper.sol';
import '../admin/AdminableInit.sol';
import '../interface/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract LiquidityStorage is AdminableInit, SwapableInit {
    using SafeMath for uint256;

    constructor() {}

    function initializeLiquidity(address _storeAdmin, address _storeSwap) public initializer {
        AdminableInit.initializeAdmin(_storeAdmin);
        SwapableInit.initializeSwap(_storeSwap);
    }

    // 将两个token（msg.sender） 换成lp 到 to
    function swapToLpToken(
        address token,
        address pair,
        uint256 amount,
        address to
    )
        external
        returns (
            uint256 exactAmountA,
            uint256 exactAmountB,
            uint256 liquidity
        )
    {
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint256 forecastTokenA;
        uint256 forecastTokenB;
        uint256 swapAmount = amount.div(2);

        if (token != token0) {
            forecastTokenA = getAmountsOut(token, token0, swapAmount);
        } else {
            forecastTokenA = swapAmount;
        }

        if (token != token1) {
            forecastTokenB = getAmountsOut(token, token1, swapAmount);
        } else {
            forecastTokenB = swapAmount;
        }

        (exactAmountA, exactAmountB) = calcAddLiquidity(pair, forecastTokenA, forecastTokenB, 0, 0);

        if (token != token0) {
            swapForExact(token, token0, exactAmountA, forecastTokenA);
        }
        if (token != token1) {
            swapForExact(token, token1, exactAmountB, forecastTokenB);
        }

        // add liquidity
        //IERC20(token0).approve(pair, exactAmountA);
        //IERC20(token1).approve(pair, exactAmountB);
        TransferHelper.safeTransferFrom(token0, address(this), pair, exactAmountA);
        TransferHelper.safeTransferFrom(token1, address(this), pair, exactAmountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    //  计算流动性
    function calcAddLiquidity(
        address pair,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private view returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(pair).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}
