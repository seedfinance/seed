// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../admin/AdminableInit.sol";
import "../LPableInit.sol";
import "../../interface/IMdexChef.sol";
import "../../interface/IMdexFactory.sol";
import "../../interface/IMdexPair.sol";
import "../../libraries/TransferHelper.sol";

contract CronAutoInvestment is AdminableInit, LPableInit {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    address public tokenReward; // pair reward address
    IMdexChef public pool; // mdx chef
    uint256 public pid;
    address public pair; // mdex pair, Address of LP contract address.

    address public receiver;

    // LpBuilderStorage lpBuilder;

    event Deposite(address pair,uint256 amount);
    event Withdraw(address pair, uint256 amount);
    event ClaimTo(uint256 amount);
    event DoHardWork(uint256 amount);

    constructor(){}

    function initialize(
        address _adminStore,
        address _lpStore,
        address _tokenReward,
        address _mdxChef,
        uint256 _mdxChefPid,
        address _pair,
        address _receiver
    ) public {
        AdminableInit.initializeAdmin(_adminStore);
        LPableInit.initializeLiquidity(_lpStore);
        tokenReward = _tokenReward;
        pool = IMdexChef(_mdxChef);
        pid = _mdxChefPid;
        pair = _pair;
        receiver = _receiver;
    }

    function addLiquidity(
        address[] calldata tokens,
        uint256[] calldata amountsDesired
    ) public returns (uint256) {
        // swap token to add liquidity
        // lpBuilder.swapToLpToken(pair,tokens,amountsDesired,address(this));
        tokenToLiquidity(pair, tokens, amountsDesired, address(this));
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        if(lpBalance > 0){
            pool.deposit(pid, lpBalance);
        }
        return lpBalance;
    }

    function removeLiquity(
        address to,
        uint liquidity
    ) public returns(uint256 amountA, uint256 amountB){
        // remove liquidity
        uint256 amount = withdraw(address(this), liquidity);
        TransferHelper.safeTransfer(tokenReward, pair, amount);
        (amountA, amountB) = IMdexPair(pair).burn(to);
    }

    function deposite(
        uint256 amount
    ) internal {
        if(amount >0 ){
            IERC20(pair).approve(address(pool), amount);
            pool.deposit(pid, amount);
        }
    }

    function withdraw(
        address to,
        uint256 liquidity
    ) internal returns(uint256) {
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        if(liquidity > lpBalance) {
            liquidity = lpBalance;
        }
        if (liquidity != 0) {
            pool.withdraw(pid, liquidity);
            TransferHelper.safeTransfer(pair, to, liquidity);
        }
        emit Withdraw(pair,liquidity);
        return liquidity;
    }

    function doHardWork() public {
        // claim inveset
        pool.withdraw(pid, 0);
        uint256 swapAmount = IERC20(tokenReward).balanceOf(address(this));
        address[] memory tokens = new address[](1);
        tokens[0] = tokenReward;
        uint[] memory amountsDesired = new uint[](1);
        amountsDesired[0] = swapAmount;
        tokenToLiquidity(pair, tokens, amountsDesired, address(this));
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        if (lpBalance >0){
            deposite(lpBalance);
        }
    }

    function claimTo() public {
        // claim inveset
        pool.withdraw(pid, 0);
        // transfer token
        uint256 claimBalance = IERC20(tokenReward).balanceOf(address(this));
        if(claimBalance >0){
            TransferHelper.safeTransfer(tokenReward, receiver, claimBalance);
        }
    }
}
