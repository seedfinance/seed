// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interface/IMdexChef.sol";
import "./interface/IMdexFactory.sol";
import "./interface/IUniswapV2Router02.sol";
import './interface/IWETH.sol';
import "./interface/IMdexPair.sol";
import "../libraries/TransferHelper.sol";
import "../interface/IStrategyManager.sol";

contract TokenInvestment is Ownable {

    address public lpToken; // mdex pair,LP contract address.
    address public factory;
    address public investment;
    IMdexChef public mdxChef; // mdx chef
    
    uint256 mdxChefPid;

    constructor(
        address _factory,
        address _lpToken,
        address _mdexChef,
        uint256 _pairId
    ) {
        factory = _factory;
        require(factory != address(0),"factory mistask");

        mdxChef = IMdexChef(_mdexChef);
        IMdexChef.MdxPoolInfo memory poolInfo = mdxChef.poolInfo(_pairId);
        lpToken = address(poolInfo.lpToken);
        require(lpToken != address(0), "lp token address mistake");
        mdxChefPid = _pairId;

    }
    function pairFor(address tokenA, address tokenB) internal view returns (address pair){
        pair = IMdexFactory(factory).getPair(tokenA, tokenB);
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) external returns (uint256 amountA,uint256 amountB,uint256 liquidity){
        require(lpToken == pairFor(tokenA, tokenB),"pair mismatch");
        (amountA,amountB,liquidity) = _addLiquidity(tokenA,tokenB,amountADesired,amountBDesired,to);
    }
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _getLiquidityAmount(tokenA, tokenB, amountADesired, amountBDesired);
        // address pair = pairFor(tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, lpToken, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, lpToken, amountB);
        liquidity = IMdexPair(lpToken).mint(to);
        
        // deposit
        // IERC20(lpToken).approve(address(mdxChef), liquidity);
        // mdxChef.deposit(mdxChefPid, liquidity);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) public returns (uint amountA, uint amountB) {
        require(
        lpToken == pairFor(tokenA, tokenB),"pair mismatch");
        uint256 lpBalance = IERC20(lpToken).balanceOf(address(this));
        if(liquidity > lpBalance){
            liquidity = lpBalance;
        }
        IMdexPair(lpToken).transfer(lpToken, liquidity);

        (amountA, amountB) = IMdexPair(lpToken).burn(to);

        // calc amount
        (amountA, amountB) = tokenA == IMdexPair(lpToken).token0() ? (amountA, amountB) : (amountB, amountA);
        require(amountA >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
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
                // require(amountBOptimal >= amountBMin, 'MdexRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = IMdexFactory(factory).quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                // require(amountAOptimal >= amountAMin, 'MdexRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // swap token
    function swapTokenToLpToken(
        address token,
        uint256 amount,
        address to
    ) public returns(uint256 amountDesiredA,uint256 amountDesiredB,uint256 lpAmount){
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        (amountDesiredA,amountDesiredB,lpAmount) =
            SwapLibrary.swapToLpToken(manager, token, lpToken, amount, to);
    }
    function swapHTToLpToken(
        address to
    ) public payable returns(uint256 amountDesiredA,uint256 amountDesiredB,uint256 lpAmount){
        // swap ht to lp token
    }
}
