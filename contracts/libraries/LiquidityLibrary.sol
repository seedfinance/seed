// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './UniswapV2Library.sol';
import './TransferHelper.sol';
import '../interface/IStrategyManager.sol';
import '../interface/IWETH.sol';

library LiquidityLibrary {
    using SafeMath for uint256;

    // addLiquidity
    // tokenA tokenB 在msg.sender手中
    // 返回流动性到 {to}
    function addLiquidity(
        address pair,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = calcAddLiquidity(pair, amountADesired, amountBDesired, amountAMin, amountBMin);
        TransferHelper.safeTransferFrom(IUniswapV2Pair(pair).token0(), msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(IUniswapV2Pair(pair).token1(), msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    // removeLiquidity
    // lp 在 msg.sender 手中
    // return token0 token1 到 {to}
    function removeLiquidity(
        address pair,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (amountA, amountB) = IUniswapV2Pair(pair).burn(to);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }

    function addLiquidityETH(
        address pair,
        address WETH,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    )
        internal
        returns (
            uint256 amount,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amount, amountETH) = calcAddLiquidity(pair, amountADesired, amountBDesired, amountAMin, amountBMin);
        address token;
        (token, amount, amountETH) = IUniswapV2Pair(pair).token1() == WETH
            ? (IUniswapV2Pair(pair).token0(), amount, amountETH)
            : (IUniswapV2Pair(pair).token1(), amountETH, amount);

        TransferHelper.safeTransferFrom(token, msg.sender, pair, amount);

        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

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
