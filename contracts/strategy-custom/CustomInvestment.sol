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

contract CustomInvestment is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public lpToken; // mdex pair, Address of LP contract address.

    IStrategyManager public manager; // manager
    IMdexChef public mdxChef; // mdx chef
    
    uint256 public mdxChefPid;
    address public tokenChef; // lpToken reward address

    address public receiver;

    event Deposite(address lpToken,uint256 amount);
    event Withdraw(address lpToken, uint256 amount);
    event ClaimTo(uint256 amount);
    event DoHardWork(uint256 amount);

    constructor(
        IStrategyManager _manager,
        address _tokenChef, // lpToken reward address
        address _mdexChef,
        uint256 _pairId,
        address _receiver
    ) public {
        manager = _manager;

        mdxChef = IMdexChef(_mdexChef);
        IMdexChef.MdxPoolInfo memory poolInfo = mdxChef.poolInfo(_pairId);
        lpToken = address(poolInfo.lpToken);
        require(lpToken != address(0), "lp token address mistake");
        mdxChefPid = _pairId;

        tokenChef = _tokenChef;
        require(tokenChef != address(0), "token chef address mistake");

        receiver = _receiver;
        require(receiver != address(0), "token chef address mistake");
    }
    function tokenToLiquidity(
        address[] calldata tokens,
        uint256[] calldata amountsDesired
    ) public returns (uint256 liquidity) {
        // swap token to add liquidity


    }
    function removeLiquity(uint liquidity) public {
        // remove liquidity
    }
    function deposite(
        address lp,
        uint256 amount
    ) public {
        require(lp == lpToken,"lpToken not match");
        if(amount >0 ){
            IERC20(lpToken).approve(address(mdxChef), amount);
            mdxChef.deposit(mdxChefPid, amount);
        }
        emit Deposite(lpToken,amount);
    }

    function withdraw(
        address to,
        uint256 liquidity
    ) public {
        if (liquidity != 0) {
            uint256 lpBalance = IERC20(lpToken).balanceOf(address(this));
            if(liquidity > lpBalance) {
                liquidity = lpBalance;
            }
            mdxChef.withdraw(mdxChefPid, liquidity);
            TransferHelper.safeTransfer(lpToken, to, liquidity);
        }
        emit Withdraw(lpToken,liquidity);
    }

    function doHardWork() public {
        // claim inveset
        mdxChef.withdraw(mdxChefPid, 0);
        // swap token
        uint256 swapAmount = IERC20(tokenChef).balanceOf(address(this));
        (, , uint256 lpAmount) =
            SwapLibrary.swapToLpToken(manager, tokenChef, lpToken, swapAmount, address(this));

        uint256 lpBalance = IERC20(lpToken).balanceOf(address(this));
        if (lpBalance >0){
            deposite(lpToken, lpBalance);
        }
        emit DoHardWork(lpBalance);
    }
    function claimTo() public {
        // claim inveset
        mdxChef.withdraw(mdxChefPid, 0);
        uint256 claimBalance = IERC20(tokenChef).balanceOf(address(this));
        if(claimBalance >0){
            TransferHelper.safeTransfer(tokenChef, receiver, claimBalance);
        }
        emit ClaimTo(claimBalance);
    }

    fallback() external {}
    receive() payable external {}
}