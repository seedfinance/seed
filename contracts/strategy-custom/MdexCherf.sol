// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IMdexChef.sol";
import "../interface/IMdexFactory.sol";
import "./interface/IWETH.sol";
import "./interface/IUniswapV2Router02.sol";
import "../interface/IMdexPair.sol";
import "./library/TransferHelper.sol";

contract CustomInvestment is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public router; // mdex swap router 
    address public factory; // chef factory
    address public lpToken; // mdex pair,LP contract address.

    IMdexChef public mdxChef; // mdx chef
    address public receiver; // rewared address

    address token0;
    address token1;

    address tokenChef; // lpToken reward address
    uint256 mdxChefPid;

    address public WETH; // WETH address
    

    constructor(
        address _receiver,
        address _router,
        address _mdxChef,
        address _tokenChef,
        uint256 _pairId
    ) public {
        receiver = _receiver;
        require(receiver != address(0),"receiver address mistake");

        router = _router;
        factory = IUniswapV2Router02(_router).factory();
        require(factory != address(0), "factory address mistake");
        
        mdxChef = IMdexChef(_mdxChef);
        IMdexChef.MdxPoolInfo memory poolInfo = mdxChef.poolInfo(_pairId);
        lpToken = address(poolInfo.lpToken);
        require(lpToken != address(0), "lp token address mistake");
        mdxChefPid = _pairId;

        token0 = IMdexPair(lpToken).token0();
        require(token0 != address(0),"token0 mistake");
        
        token1 = IMdexPair(lpToken).token1();
        require(token1 != address(0),"token1 mistake");

        WETH = IUniswapV2Router02(_router).WHT();
        require(WETH != address(0),"WETH mistake");

        tokenChef = _tokenChef;
        require(tokenChef != address(0),"tokenChef mistake");

    }

    function addLiquidity(
        address[] calldata tokens,
        uint256[] calldata amountsDesired,
        address forAddr
    ) public payable returns(uint256 _amount){
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 remainAmount;
        if(tokens.length == 0){ // only HT
            require(msg.value > 0 ,"ht value error");
            // HT to WHT
            IWETH(WETH).deposit{value : msg.value}();
            (amountADesired,amountBDesired,remainAmount) = swapExactToken(WETH);
        }else if(tokens.length == 1) { // Token or HT
            require(tokens[0] != address(0),"token0 address mistake");
            if(msg.value == 0){ // only Token
                (amountADesired,amountBDesired,remainAmount) = swapExactToken(tokens[0]);
            } else { // Token + HT
                require(tokens[1] == WETH,"token1 must be WHT");
                address pair = pairFor(tokens[0], tokens[1]); // token[1] == WETH
                require(pair == lpToken, "wrong pid");
                (amountADesired,amountBDesired) = _getLiquidityAmount(token0, token1, amountsDesired[0], msg.value);
                require(amountBDesired <= msg.value,"not enough ht");
                remainAmount = msg.value.sub(amountBDesired);
                IWETH(WETH).deposit{value : msg.value}();
            }
        }else { // Token + Token
            address pair = pairFor(tokens[0], tokens[1]);
            require(pair == lpToken, "wrong pid");
            amountADesired = amountsDesired[0];
            amountBDesired = amountsDesired[1];
        }
        if (amountADesired != 0) {
            (, , _amount) = _addLiquidityExternal(token0, token1, amountADesired, amountBDesired,forAddr);
           IERC20(lpToken).approve(address(mdxChef), _amount);
            mdxChef.deposit(mdxChefPid, _amount);
        }
        // refund dust HT, if origin is HT
        if (msg.value > 0 && remainAmount > 0) {
            IWETH(WETH).withdraw(remainAmount);
            TransferHelper.safeTransferETH(msg.sender, remainAmount);
        }

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
        TransferHelper.safeTransfer(tokenA, lpToken, amountA);
        TransferHelper.safeTransfer(tokenB, lpToken, amountB);
        liquidity = IMdexPair(lpToken).mint(to);
    }
    function _addLiquidityExternal(
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
    function removeLiquidity(
        address to,
        uint256 liquidity
    ) public {
        if (liquidity > 0) {
            uint256 lpBalance = IERC20(lpToken).balanceOf(address(this));
            if(liquidity > lpBalance) {
                liquidity = lpBalance;
            }
            mdxChef.withdraw(mdxChefPid, liquidity);
            _removeLiquidity(token0, token1, liquidity, to);
        }
    }
    // get token
    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        // address pair = pairFor(tokenA, tokenB);
        IMdexPair(lpToken).transfer(lpToken, liquidity);
        // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IMdexPair(lpToken).burn(to);
        (address tokenPair,) = IMdexFactory(factory).sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == tokenPair ? (amount0, amount1) : (amount1, amount0);
    }
   function getSwapPath(address tokenA,address tokenB) internal view returns(address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
   }
   function getAmountsOut(address tokenA,address tokenB,uint256 amountA) internal view returns(uint256){
        address[] memory path = getSwapPath(tokenA, tokenB);
        uint256[] memory amountBout = IMdexFactory(factory).getAmountsOut(amountA,path);
        return amountBout[amountBout.length - 1];
   }
   function pairFor(address tokenA, address tokenB) internal view returns (address pair){
        pair = IMdexFactory(factory).getPair(tokenA, tokenB);
    }
    function swap(
        address fromTokenAddress,
        address toTokenAddress, 
        uint fromAmount, 
        uint minToAmount) internal returns(uint){
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(router);
        address[] memory path = getSwapPath(fromTokenAddress, toTokenAddress);
        IERC20 fromToken  = IERC20(fromTokenAddress);
        fromToken.approve(router, 0);
        fromToken.approve(router, fromAmount);
        uint256[] memory amounts = swapRouter.swapExactTokensForTokens(
            fromAmount, minToAmount, path, address(this), block.timestamp);
        uint256 amount = amounts[amounts.length - 1];
        return amount;
    }
    function swapToken(address fromAddress) internal  returns(uint){
        uint256 swapAmount = IERC20(fromAddress).balanceOf(address(this)).div(2);
        if(token0 != fromAddress) {
            swap(fromAddress,token0, swapAmount, 0);
        }
        if (token1 != fromAddress) {
            swap(fromAddress, token1, swapAmount, 0);
        }
        return swapAmount;
    }
    function swapExactToken(address fromAddress) internal returns(uint256,uint256,uint256) {
        uint256 swapAmount = IERC20(fromAddress).balanceOf(address(this)).div(2);
        uint256 amountA = swapAmount;
        uint256 amountB = swapAmount;
        
        if(token0 != fromAddress) {
            amountA = getAmountsOut(fromAddress, token0, swapAmount);
        }
        if (token1 != fromAddress) {
            amountB = getAmountsOut(fromAddress, token1, swapAmount);
        }
        (uint256 amountADesired, uint256 amountBDesired) = _getLiquidityAmount(token0, token1, amountA, amountB);

        amountA = amountADesired.mul(swapAmount).div(amountA);
        require(amountA <= swapAmount, "not enough token");
        amountB = amountBDesired.mul(swapAmount).div(amountB);
        require(amountB <= swapAmount, "not enough token");
        
        if(token0 != fromAddress) {
            swap(fromAddress,token0, amountA, 0);
        }
        if (token1 != fromAddress) {
            swap(fromAddress, token1, amountB, 0);
        }
        uint256 remainAmount = amountA.add(amountB).sub(swapAmount);
        return (amountADesired,amountBDesired,remainAmount);
    }
    function doHardWork() public {
        
        // claim inveset
        mdxChef.withdraw(mdxChefPid, 0);
        // swap token
        swapToken(tokenChef);
        
        uint256 amountADesired = IERC20(token0).balanceOf(address(this));
        uint256 amountBDesired = IERC20(token1).balanceOf(address(this));
        uint256 _amount;
        (, , _amount) = _addLiquidity(token0, token1, amountADesired, amountBDesired, address(this));
        IERC20(lpToken).approve(address(mdxChef), _amount);
        mdxChef.deposit(mdxChefPid, _amount);
    }
    function claimTo() public {
        // claim inveset
        mdxChef.withdraw(mdxChefPid, 0);
        uint256 claimBalance = IERC20(tokenChef).balanceOf(address(this));
        if(claimBalance >0){
            TransferHelper.safeTransfer(tokenChef, receiver, claimBalance);
        }
    }
    fallback() external {}
    receive() payable external {}
}