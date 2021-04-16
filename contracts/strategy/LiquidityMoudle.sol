// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "../libraries/LiquidityLibrary.sol";

contract LiquidityMoudle is Ownable {

    IUniswapV2Pair public pair;
    address public factory;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(
        address _factory,
        IUniswapV2Pair _pair
    ) {
        factory = _factory;
        pair = _pair;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        require(
            address(pair) == IUniswapV2Factory(factory).getPair(tokenA, tokenB),
            "pair mismatch"
        );
        (amountADesired, amountBDesired, amountAMin, amountBMin) = pair
            .token0() == tokenA
            ? (amountADesired, amountBDesired, amountAMin, amountBMin)
            : (amountBDesired, amountADesired, amountBMin, amountAMin);

        (amountA, amountB, liquidity) = LiquidityLibrary.addLiquidity(
            address(pair),
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to
        );
        (amountA, amountB) = pair.token0() == tokenA ? (amountA, amountB) : (amountB, amountA);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        require(
            address(pair) == IUniswapV2Factory(factory).getPair(tokenA, tokenB),
            "pair mismatch"
        );
        // send liquidity to pair
        pair.transferFrom(msg.sender, address(pair), liquidity);
        (amountA, amountB) = pair.burn(to);

        // calc amount
        (amountA, amountB) = tokenA == pair.token0() ? (amountA, amountB) : (amountB, amountA);
        require(amountA >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
    }
}
