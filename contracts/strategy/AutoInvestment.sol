// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../interface/IMasterChef.sol';
import '../libraries/TransferHelper.sol';
import '../libraries/SwapLibrary.sol';
import '../interface/IStrategyManager.sol';

contract AutoInvestment is Ownable, Pausable, ERC20 {
    using SafeMath for uint256;

    event Deposit(address indexed forAddr, uint256 share);
    event Withdraw(address indexed forAddr, uint256 share);

    IStrategyManager public manager;

    IMasterChef public chef;
    address public chefToken;
    uint256 public chefPid;
    address public lpToken;

    uint256 totalAmounts;

    constructor(
        IStrategyManager _manager,
        IMasterChef _chef,
        address _chefToken,
        address _lpToken,
        uint256 _pid
    )
        ERC20(
            string(abi.encodePacked("x'", TransferHelper.safeName(_lpToken))),
            string(abi.encodePacked("x'", TransferHelper.safeSymbol(_lpToken)))
        )
    {
        (lpToken, , , ) = _chef.poolInfo(_pid);
        assert(lpToken == _lpToken);

        manager = _manager;
        chef = _chef;
        chefToken = _chefToken;
        chefPid = _pid;

        if (TransferHelper.safeDecimals(lpToken) != 18) {
            _setupDecimals(TransferHelper.safeDecimals(lpToken));
        }
    }

    // deposit lp token
    function deposit(address forAddr) external payable whenNotPaused {
        _doHardWork();

        uint256 amount = IERC20(lpToken).balanceOf(address(this));

        if (amount == 0) {
            return;
        }
        uint256 share;
        if (totalSupply() == 0 || totalAmounts == 0) {
            share = amount;
        } else {
            share = amount.mul(totalSupply()).div(totalAmounts);
        }

        _mint(forAddr, share);
        _approve(forAddr, msg.sender, allowance(forAddr, msg.sender).add(share));

        totalAmounts = totalAmounts.add(amount);

        IERC20(lpToken).approve(address(chef), amount);
        chef.deposit(chefPid, amount);

        emit Deposit(forAddr, share);
    }

    // withdraw lp token;
    function withdraw(address to) external {
        if (!paused()) {
            _doHardWork();
        }
        uint256 share = balanceOf(address(this));

        if (share == 0) {
            return;
        }
        // calc amount
        uint256 what = share.mul(totalAmounts).div(totalSupply());

        uint256 localAmounts = IERC20(lpToken).balanceOf(address(this));
        if (what > localAmounts) {
            chef.withdraw(chefPid, what.sub(localAmounts));
        }

        _burn(address(this), share);
        TransferHelper.safeTransfer(lpToken, to, what);
        totalAmounts = totalAmounts.sub(what);
        emit Withdraw(to, share);
    }

    function emergencyWithdraw() external onlyOwner {
        chef.emergencyWithdraw(chefPid);
        _pause();
    }

    function doHardWork() external whenNotPaused {
        _doHardWork();
    }

    function _doHardWork() private {
        // claim the earnings
        chef.withdraw(chefPid, 0);

        // reinvest
        uint256 swapAmount = IERC20(chefToken).balanceOf(address(this));
        if (swapAmount > 0) {
            (, , uint256 lpAmount) = SwapLibrary.swapToLpToken(manager, chefToken, lpToken, swapAmount, address(this));
            totalAmounts = totalAmounts.add(lpAmount);
            IERC20(lpToken).approve(address(chef), lpAmount);
            chef.deposit(chefPid, lpAmount);
        }
    }
}
