// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../strategy/AutoInvestment.sol';
// import '../libraries/LiquidityLibrary.sol';
import '../libraries/TransferHelper.sol';

contract AutoInvestmentRouter {
    // modifier ensure(uint256 deadline) {
    //     require(deadline >= block.timestamp, 'Router: EXPIRED');
    //     _;
    // }
    // spec
    // address public WETH;

    // constructor(address _WETH) {
    //     WETH = _WETH;
    // }

    function deposit(
        address automoulde,
        address pair,
        uint256 amount,
        address to
    ) external {
        TransferHelper.safeTransferFrom(pair, msg.sender, automoulde, amount);
        AutoInvestment(automoulde).deposit(to);
    }

    function withdraw(
        address automoulde,
        uint256 liquidity,
        address to
    ) external {
        TransferHelper.safeTransferFrom(automoulde, msg.sender, automoulde, liquidity);
        AutoInvestment(automoulde).withdraw(to);
    }

    // function addLiquidity(
    //     address pair,
    //     uint256 amountADesired,
    //     uint256 amountBDesired,
    //     uint256 amountAMin,
    //     uint256 amountBMin,
    //     address to,
    //     uint256 deadline
    // )
    //     external
    //     ensure(deadline)
    //     returns (
    //         uint256 amountA,
    //         uint256 amountB,
    //         uint256 liquidity
    //     )
    // {
    //     address automoulde = spec.getAutoInvestment(pair);
    //     (amountA, amountB, liquidity) = LiquidityLibrary.addLiquidity(pair, amountADesired, amountBDesired, amountAMin, amountBMin, automoulde);
    //     AutoInvestment(automoulde).deposit(to);
    // }

    // function removeLiquidity(
    //     address automoulde,
    //     uint256 liquidity,
    //     uint256 amountAMin,
    //     uint256 amountBMin,
    //     address to,
    //     uint256 deadline
    // ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
    //     address pair = AutoInvestment(automoulde).lpToken();
    //     TransferHelper.safeTransferFrom(automoulde, msg.sender, automoulde, liquidity);

    //     AutoInvestment(automoulde).withdraw(pair);
    //     (amountA, amountB) = IUniswapV2Pair(pair).burn(to);

    //     require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
    //     require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    // }

    // function addLiquidityETH(
    //     address pair,
    //     uint256 amountTokenDesired,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // )
    //     external
    //     payable
    //     ensure(deadline)
    //     returns (
    //         uint256 amountToken,
    //         uint256 amountETH,
    //         uint256 liquidity
    //     )
    // {
    //     address automoulde = spec.getAutoInvestment(pair);

    //     uint256 amountETHDesired = msg.value;

    //     if (IUniswapV2Pair(pair).token1() == WETH) {
    //         (amountToken, amountETH, liquidity) = LiquidityLibrary.addLiquidityETH(
    //             pair,
    //             WETH,
    //             amountTokenDesired,
    //             amountETHDesired,
    //             amountTokenMin,
    //             amountETHMin,
    //             to
    //         );
    //     } else {
    //         (amountToken, amountETH, liquidity) = LiquidityLibrary.addLiquidityETH(
    //             pair,
    //             WETH,
    //             amountETHDesired,
    //             amountTokenDesired,
    //             amountETHMin,
    //             amountTokenMin,
    //             to
    //         );
    //     }
    //     AutoInvestment(automoulde).deposit(to);
    // }

    // function removeLiquidityETH(
    //     address automoulde,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) public ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
    //     address pair = AutoInvestment(automoulde).lpToken();
    //     require(IUniswapV2Pair(pair).token0() == WETH || IUniswapV2Pair(pair).token1() == WETH, 'no weth');
    //     // send liquidity to pair
    //     TransferHelper.safeTransferFrom(automoulde, msg.sender, automoulde, liquidity);

    //     AutoInvestment(automoulde).withdraw(pair);
    //     (amountToken, amountETH) = IUniswapV2Pair(pair).burn(address(this));

    //     // calc amount
    //     (amountToken, amountETH) = IUniswapV2Pair(pair).token1() == WETH ? (amountToken, amountETH) : (amountETH, amountToken);
    //     require(amountToken >= amountTokenMin, 'INSUFFICIENT_A_AMOUNT');
    //     require(amountETH >= amountETHMin, 'INSUFFICIENT_B_AMOUNT');

    //     address token = IUniswapV2Pair(pair).token1() == WETH ? IUniswapV2Pair(pair).token0() : IUniswapV2Pair(pair).token1();
    //     TransferHelper.safeTransfer(token, to, amountToken);
    //     IWETH(WETH).withdraw(amountETH);
    //     TransferHelper.safeTransferETH(to, amountETH);
    // }
}
