// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../interface/IWETH.sol";

import "../libraries/LiquidityLibrary.sol";

contract LiquidityETHMoudle is Ownable {

    IUniswapV2Pair public pair;
    address public factory;
    address public WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(
        address _WETH,
        address _factory,
        IUniswapV2Pair _pair
    ) {
        WETH = _WETH;
        factory = _factory;
        pair = _pair;
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external payable ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        require(
            address(pair) == IUniswapV2Factory(factory).getPair(token, WETH),
            "pair mismatch"
        );
        uint256 amountETHDesired = msg.value;

        (amountTokenDesired, amountETHDesired, amountTokenMin, amountETHMin) = pair
            .token0() == token
            ? (amountTokenDesired, amountETHDesired, amountTokenMin, amountETHMin)
            : (amountETHDesired, amountTokenDesired, amountETHMin, amountTokenMin);


        (amountToken, amountETH, liquidity) = LiquidityLibrary.addLiquidityETH(
            address(pair),
            WETH,
            amountTokenDesired,
            amountETHDesired,
            amountTokenMin,
            amountETHMin,
            to
        );
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountETH) {
        require(
            address(pair) == IUniswapV2Factory(factory).getPair(token, WETH),
            "pair mismatch"
        );
        // send liquidity to pair
        pair.transferFrom(msg.sender, address(pair), liquidity);
        (amountToken, amountETH) = pair.burn(address(this));

        // calc amount
        (amountToken, amountETH) = token == pair.token0() ? (amountToken, amountETH) : (amountETH, amountToken);
        require(amountToken >= amountTokenMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountETH >= amountETHMin, 'INSUFFICIENT_B_AMOUNT');

        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
}
