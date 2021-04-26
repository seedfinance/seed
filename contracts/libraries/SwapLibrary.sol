// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;
import '../interface/ISwapStorage.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

library SwapLibrary {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'Illegal token address');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Illegal token address');
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(fee); //997
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function _addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (uint256 reserveA, uint256 reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
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
        (amountA, amountB) = _addLiquidity(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        IERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityWithPermit(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (uint256 amountA, uint256 amountB) {
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(pair, tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
    }

    function _swap(
        uint256[] memory amounts,
        ISwapStorage.PathItem memory item,
        address _to
    ) internal {
        for (uint256 i; i < item.path.length - 1; i++) {
            (address input, address output) = (item.path[i], item.path[i + 1]);
            (address token0, ) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < item.path.length - 2 ? item.pair[i + 1] : _to;
            IUniswapV2Pair(item.pair[i]).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function getAmountsOutWithFee(
        uint256 amountIn,
        uint256 fee,
        ISwapStorage.PathItem memory item
    ) internal view returns (uint256[] memory amounts) {
        require(item.path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](item.path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < item.path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(item.pair[i]).getReserves();
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    function getAmountsOut(uint256 amountIn, ISwapStorage.PathItem memory item) internal view returns (uint256[] memory amounts) {
        return getAmountsOutWithFee(amountIn, 997, item);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        ISwapStorage.PathItem memory item,
        address to
    ) internal returns (uint256[] memory amounts) {
        amounts = getAmountsOut(amountIn, item);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        IERC20(item.path[0]).safeTransferFrom(msg.sender, item.pair[0], amounts[0]);
        _swap(amounts, item, to);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountsInWithFee(
        uint256 amountOut,
        uint256 fee,
        ISwapStorage.PathItem memory item
    ) internal view returns (uint256[] memory amounts) {
        require(item.path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](item.path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = item.path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(item.pair[i - 1]).getReserves();
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    function getAmountsIn(uint256 amountOut, ISwapStorage.PathItem memory item) internal view returns (uint256[] memory amounts) {
        return getAmountsInWithFee(amountOut, 997, item);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        ISwapStorage.PathItem memory item,
        address to
    ) internal returns (uint256[] memory amounts) {
        amounts = getAmountsIn(amountOut, item);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IERC20(item.path[0]).safeTransferFrom(msg.sender, item.pair[0], amounts[0]);
        _swap(amounts, item, to);
    }

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
            uint256 amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function swapToLpToken(
        ISwapStorage swapStorage,
        address token,
        address lpToken,
        uint256 swapAmount,
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
        swapAmount = swapAmount.div(2);
        ISwapStorage.PathItem memory item0;
        ISwapStorage.PathItem memory item1;

        if (token != token0) {
            item0 = swapStorage.pathFor(token, token0);
            uint256[] memory amounts = getAmountsOut(swapAmount, item0);
            forecastTokenA = amounts[amounts.length - 1];
        } else {
            forecastTokenA = swapAmount;
        }
        if (token != token1) {
            item1 = swapStorage.pathFor(token, token1);
            uint256[] memory amounts = getAmountsOut(swapAmount, item1);
            forecastTokenB = amounts[amounts.length - 1];
        } else {
            forecastTokenB = swapAmount;
        }

        (exactAmountA, exactAmountB) = calcAddLiquidity(lpToken, forecastTokenA, forecastTokenB, 0, 0);

        if (token != token0) {
            swapTokensForExactTokens(exactAmountA, swapAmount, item0, lpToken);
        } else {
            IERC20(token).safeTransferFrom(msg.sender, lpToken, exactAmountA);
        }
        if (token != token1) {
            swapTokensForExactTokens(exactAmountB, swapAmount, item1, lpToken);
        } else {
            IERC20(token).safeTransferFrom(msg.sender, lpToken, exactAmountB);
        }
        // add liquidity
        liquidity = IUniswapV2Pair(lpToken).mint(to);
    }
}
