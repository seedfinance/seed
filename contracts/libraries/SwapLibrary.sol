// SPDX-License-Identifier: MIT

pragma solidity =0.7.2;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interface/ISwapStorage.sol";

library SwapLibrary {
    using SafeMath for uint;

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

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(fee); //997
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function _addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (uint reserveA, uint reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
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
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        SafeERC20.safeTransferFrom(IERC20(tokenA), msg.sender, pair, amountA);
        SafeERC20.safeTransferFrom(IERC20(tokenB), msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal returns (uint amountA, uint amountB) {
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityWithPermit(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) internal returns (uint amountA, uint amountB) {
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(pair, tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
    }

    function _swap(uint[] memory amounts, address[] memory path, address[] memory pair, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pair[i + 1] : _to;
            IUniswapV2Pair(pair[i]).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function getAmountsOutWithFee(
        uint256 amountIn,
        uint256 fee,
        address[] memory path,
        address[] memory pair
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut,) = IUniswapV2Pair(pair[i]).getReserves();
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path,
        address[] memory pair
    ) internal view returns (uint256[] memory amounts) {
        return getAmountsOutWithFee(amountIn, 997, path, pair);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata pair,
        address to
    ) internal returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, path, pair);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        SafeERC20.safeTransferFrom(
            IERC20(path[0]), msg.sender, pair[0], amounts[0]
        );
        _swap(amounts, path, pair, to);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountsInWithFee(
        uint amountOut, 
        uint256 fee, 
        address[] memory path, 
        address[] memory pair
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, ) = IUniswapV2Pair(pair[i - 1]).getReserves();
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    function getAmountsIn(
        uint amountOut, 
        address[] memory path, 
        address[] memory pair
    ) internal view returns (uint[] memory amounts) {
        return getAmountsInWithFee(amountOut, 997, path, pair);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address[] memory pair,
        address to
    ) internal returns (uint[] memory amounts) {
        amounts = getAmountsIn(amountOut, path, pair);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        SafeERC20.safeTransferFrom(
            IERC20(path[0]), msg.sender, pair[0], amounts[0]
        );
        _swap(amounts, path, pair, to);
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
        ISwapStorage.PathItem memory item0;
        ISwapStorage.PathItem memory item1;

        if (token != token0) {
            item0 = swapStorage.pathFor(token, token0);
            uint256[] memory amounts = getAmountsOut(swapAmount, item0.path, item0.pair);
            forecastTokenA = amounts[amounts.length - 1];
        } else {
            forecastTokenA = swapAmount;
        }
        if (token != token1) {
            item1 = swapStorage.pathFor(token, token1);
            uint256[] memory amounts = getAmountsOut(swapAmount, item1.path, item1.pair);
            forecastTokenB = amounts[amounts.length - 1];
        } else {
            forecastTokenB = swapAmount;
        }

        (exactAmountA, exactAmountB) = calcAddLiquidity(lpToken, forecastTokenA, forecastTokenB, 0, 0);

        if (token != token0) {
            swapTokensForExactTokens(exactAmountA, swapAmount, item0.path, item0.pair, address(this));
        }
        if (token != token1) {
            swapTokensForExactTokens(exactAmountB, swapAmount, item1.path, item1.pair, address(this));
        }

        // add liquidity
        IERC20(token0).approve(lpToken, exactAmountA);
        IERC20(token1).approve(lpToken, exactAmountB);
        SafeERC20.safeTransferFrom(IERC20(token0), address(this), lpToken, exactAmountA);
        SafeERC20.safeTransferFrom(IERC20(token1), address(this), lpToken, exactAmountB);
        liquidity = IUniswapV2Pair(lpToken).mint(to);
    }
}
