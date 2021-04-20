// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IMdexChef.sol";
import "../interface/IMdexFactory.sol";
import "../interface/IMdexPair.sol";
import "../libraries/TransferHelper.sol";
import "../interface/IStrategyManager.sol";
import "../libraries/SwapLibrary.sol";

contract SwapToLPToken is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public lpToken; // mdex pair,LP contract address.
    address public factory;
    IMdexChef public mdxChef; // mdx chef
    
    uint256 mdxChefPid;

    address public token0;
    address public token1;

    IStrategyManager public manager; // manager

    constructor(
        IStrategyManager _manager, // manager
        address _factory, // factory
        address _lpToken, // lp token
        address _mdexChef, // pool address
        uint256 _pairId // pair id
    ) {
        manager = _manager;

        factory = _factory;
        require(factory != address(0),"factory mistask");

        mdxChef = IMdexChef(_mdexChef);
        IMdexChef.MdxPoolInfo memory poolInfo = mdxChef.poolInfo(_pairId);
        lpToken = address(poolInfo.lpToken);
        require(lpToken != address(0), "lp token address mistake");
        mdxChefPid = _pairId;

        token0 = IMdexPair(lpToken).token0();
        require(token0 != address(0),"token0 mistake");
        
        token1 = IMdexPair(lpToken).token1();
        require(token1 != address(0),"token1 mistake");
    }
    
    function tokenToLiquidity(
        address[] calldata tokens,
        uint256[] calldata amountsDesired,
        address to
    ) public returns(uint256 amountA, uint256 amountB, uint256 liquidity){
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 lpAmount;
        require(tokens.length == amountsDesired.length,"tokens and amount length not correspond");
        require(tokens.length > 0,"must be one token");
        if(tokens.length == 1) { // only one Token
            require(tokens[0] != address(0),"token0 address mistake");
            (amountADesired,amountBDesired,lpAmount) = swapTokenAddLiquidity(tokens[0],amountsDesired[0]);
        }else { // Token + Token
            address pair = pairFor(tokens[0], tokens[1]);
            require(pair == lpToken, "wrong pid");
            amountADesired = amountsDesired[0];
            amountBDesired = amountsDesired[1];
            (amountADesired,amountBDesired) = 
                token0 == tokens[0] ? (amountADesired, amountBDesired):(amountBDesired, amountADesired);
            (amountA, amountB, liquidity) = _addLiquidity(token0, token1, amountADesired, amountBDesired, to);
        }
    }
    function tokenRemoveLiquidity(
        address tokenChef,
        address pair,
        uint liquidity,
        address to
    ) public returns (uint amountA, uint amountB) {
        require(pair == lpToken,"lptoken mistake");
        TransferHelper.safeTransferFrom(tokenChef, msg.sender, lpToken, liquidity);
        (amountA, amountB) = IMdexPair(lpToken).burn(to);
        // calc amount
        (amountA, amountB) = token0 == IMdexPair(lpToken).token0() ? (amountA, amountB) : (amountB, amountA);
    }

    // function addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint256 amountADesired,
    //     uint256 amountBDesired,
    //     address to
    // ) external returns (uint256 amountA,uint256 amountB,uint256 liquidity){
    //     require(lpToken == pairFor(tokenA, tokenB),"pair mismatch");
    //     (amountA,amountB,liquidity) = _addLiquidityExternal(tokenA,tokenB,amountADesired,amountBDesired,to);
    // }
    // function _addLiquidityExternal(
    //     address tokenA,
    //     address tokenB,
    //     uint256 amountADesired,
    //     uint256 amountBDesired,
    //     address to
    // ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
    //     (amountA, amountB) = _getLiquidityAmount(tokenA, tokenB, amountADesired, amountBDesired);
    //     // address pair = pairFor(tokenA, tokenB);
    //     TransferHelper.safeTransferFrom(tokenA, msg.sender, lpToken, amountA);
    //     TransferHelper.safeTransferFrom(tokenB, msg.sender, lpToken, amountB);
    //     liquidity = IMdexPair(lpToken).mint(to);
    // }
    // function removeLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to
    // ) public returns (uint amountA, uint amountB) {
    //     require(
    //     lpToken == pairFor(tokenA, tokenB),"pair mismatch");
    //     uint256 lpBalance = IERC20(lpToken).balanceOf(address(this));
    //     if(liquidity > lpBalance){
    //         liquidity = lpBalance;
    //     }
    //     IMdexPair(lpToken).transfer(lpToken, liquidity);

    //     (amountA, amountB) = IMdexPair(lpToken).burn(to);

    //     // calc amount
    //     (amountA, amountB) = tokenA == IMdexPair(lpToken).token0() ? (amountA, amountB) : (amountB, amountA);
    //     require(amountA >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
    //     require(amountB >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
    // }
    
    function pairFor(address tokenA, address tokenB) internal view returns (address pair){
        pair = IMdexFactory(factory).getPair(tokenA, tokenB);
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
    function swapTokenAddLiquidity(address tokenAddr, uint256 swapAmount) internal returns(uint256,uint256,uint256) {
        (uint256 amountADesired, uint256 amountBDesired, uint256 lpAmount) =
            SwapLibrary.swapToLpToken(manager, tokenAddr, lpToken, swapAmount, address(this));
        return (amountADesired,amountBDesired,lpAmount);
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
        // TransferHelper.safeTransfer(tokenA, lpToken, amountA);
        // TransferHelper.safeTransfer(tokenB, lpToken, amountB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, lpToken, amountADesired);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, lpToken, amountBDesired);

        liquidity = IMdexPair(lpToken).mint(to);
    }
}
