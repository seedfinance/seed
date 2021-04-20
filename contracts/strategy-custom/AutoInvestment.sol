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

import "../libraries/SwapLibrary.sol";
import "../interface/IStrategyManager.sol";

contract AutoInvestment is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public pair; // mdex pair, Address of LP contract address.

    IMdexChef public mdxChef; // mdx chef
    
    uint256 public mdxChefPid;
    address public tokenReward; // pair reward address
    address public receiver;
    
    // LpBuilderStorage lpBuilder;

    event Deposite(address pair,uint256 amount);
    event Withdraw(address pair, uint256 amount);
    event ClaimTo(uint256 amount);
    event DoHardWork(uint256 amount);

    constructor(){}

    function initialize(
        address _tokenReward,
        address _mdxChef,
        uint256 _mdxChefPid,
        address _pair,
        address _receiver
        // address _lpBuilderStorage
    ) public {
        tokenReward = _tokenReward;
        mdxChef = IMdexChef(_mdxChef);
        mdxChefPid = _mdxChefPid;
        pair = _pair;
        receiver = _receiver;
        // lpBuilder = LpBuilderStorage.initialize(_lpBuilderStorage);
    }

    function addLiquidity(
        address[] calldata tokens,
        uint256[] calldata amountsDesired
    ) public returns (uint256) {
        // swap token to add liquidity
        // lpBuilder.swapToLpToken(pair,tokens,amountsDesired,address(this));
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        if(lpBalance > 0){
            mdxChef.deposit(mdxChefPid, lpBalance);
        }
        return lpBalance;
    }
    function removeLiquity(
        address to,
        uint liquidity
    ) public returns(uint256 amountA, uint256 amountB){
        // remove liquidity
        uint256 amount = withdraw(address(this),liquidity);
        TransferHelper.safeTransfer(tokenReward, pair, amount);
        (amountA, amountB) = IMdexPair(pair).burn(to);
    }

    function deposite(
        address lpToken,
        uint256 amount
    ) public {
        require(lpToken == pair,"lpToken not match");
        if(amount >0 ){
            IERC20(pair).approve(address(mdxChef), amount);
            mdxChef.deposit(mdxChefPid, amount);
        }
        emit Deposite(lpToken,amount);
    }

    function withdraw(
        address to,
        uint256 liquidity
    ) public returns(uint256) {
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        if(liquidity > lpBalance) {
            liquidity = lpBalance;
        }
        if (liquidity != 0) {
            mdxChef.withdraw(mdxChefPid, liquidity);
            TransferHelper.safeTransfer(pair, to, liquidity);
        }
        emit Withdraw(pair,liquidity);
        return liquidity;
    }

    function doHardWork() public {
        // claim inveset
        mdxChef.withdraw(mdxChefPid, 0);
        // swap token
        uint256 swapAmount = IERC20(tokenReward).balanceOf(address(this));
        
        /*
        (, , uint256 lpAmount) =
            SwapLibrary.swapTopair(manager, tokenReward, pair, swapAmount, address(this));
        */
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        if (lpBalance >0){
            deposite(pair, lpBalance);
        }
        emit DoHardWork(lpBalance);
    }

    function claimTo() public {
        // claim inveset
        mdxChef.withdraw(mdxChefPid, 0);
        // transfer token
        uint256 claimBalance = IERC20(tokenReward).balanceOf(address(this));
        if(claimBalance >0){
            TransferHelper.safeTransfer(tokenReward, receiver, claimBalance);
        }
        emit ClaimTo(claimBalance);
    }

    fallback() external {}
    receive() payable external {}
}