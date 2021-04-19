// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './UniswapV2Library.sol';
import './TransferHelper.sol';
import '../interface/IStrategyManager.sol';

library SwapLibrary {
    using SafeMath for uint256;

    // 将两个token（msg.sender） 换成lp 到 to
    function swapToLpToken(
        IStrategyManager manager,
        address token,
        address lpToken,
        uint256 amount,
        address to
    )
        internal
        returns (
            uint256 exactAmountA,
            uint256 exactAmountB,
            uint256 liquidity
        )
    {
        address token0 = IUniswapV2Pair(lpToken).token0();
        address token1 = IUniswapV2Pair(lpToken).token1();

        // get spec

        uint256 forecastTokenA;
        uint256 forecastTokenB;
        uint256 swapAmount = amount.div(2);

        if (token != token0) {
            (address factory0, address[] memory path0) = manager.pathFor(token, token0);
            uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory0, swapAmount, path0);
            forecastTokenA = amounts[amounts.length - 1];
        } else {
            forecastTokenA = swapAmount;
        }

        if (token != token1) {
            (address factory1, address[] memory path1) = manager.pathFor(token, token1);
            uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory1, swapAmount, path1);
            forecastTokenB = amounts[amounts.length - 1];
        } else {
            forecastTokenB = swapAmount;
        }

        (exactAmountA, exactAmountB) = calcAddLiquidity(lpToken, forecastTokenA, forecastTokenB, 0, 0);

        if (token != token0) {
            (address factory0, address[] memory path0) = manager.pathFor(token, token0);
            swapTokensForExactTokens(factory0, exactAmountA, swapAmount, path0, address(this));
        }
        if (token != token1) {
            (address factory1, address[] memory path1) = manager.pathFor(token, token1);
            swapTokensForExactTokens(factory1, exactAmountB, swapAmount, path1, address(this));
        }

        // add liquidity
        IERC20(token0).approve(lpToken, exactAmountA);
        IERC20(token1).approve(lpToken, exactAmountB);
        TransferHelper.safeTransferFrom(token0, address(this), lpToken, exactAmountA);
        TransferHelper.safeTransferFrom(token1, address(this), lpToken, exactAmountB);
        liquidity = IUniswapV2Pair(lpToken).mint(to);
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

    function swapTokensForExactTokens(
        address factory,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to
    ) private returns (uint256[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(factory, amounts, path, to);
    }

    function _swap(
        address factory,
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) private {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}
