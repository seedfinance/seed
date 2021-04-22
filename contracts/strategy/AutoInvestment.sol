// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../interface/IMdexChef.sol';
import '../libraries/TransferHelper.sol';
import "../cron/LPableInit.sol";
import "../admin/Adminable.sol";
contract AutoInvestment is Adminable, LPableInit, Pausable, ERC20 {
    using SafeMath for uint256;

    event Deposit(address indexed forAddr, uint256 share, uint256 amount);
    event Withdraw(address indexed forAddr, uint256 share, uint256 amount);

    IMdexChef public chef;
    address public chefToken;
    uint256 public chefPid;
    address public lpToken;

    uint256 totalAmounts;
    mapping (address => uint256) public depositPrice;

    constructor(
        address _store,
        address _lpStore,
        IMdexChef _chef,
        address _chefToken,
        address _lpToken,
        uint256 _pid
    ) Adminable(_store)
        ERC20(
            string(abi.encodePacked("x'", TransferHelper.safeName(_lpToken))),
            string(abi.encodePacked("x'", TransferHelper.safeSymbol(_lpToken)))
        )
    {
        LPableInit.initializeLiquidity(_lpStore);
        (lpToken, , , , ,) = _chef.poolInfo(_pid);
        assert(lpToken == _lpToken);

        chef = _chef;
        chefToken = _chefToken;
        chefPid = _pid;

        if (TransferHelper.safeDecimals(lpToken) != 18) {
            _setupDecimals(TransferHelper.safeDecimals(lpToken));
        }
    }

    // deposit lp token
    function deposit(address forAddr) external whenNotPaused {
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
        depositPrice[forAddr] = totalSupply().div(totalAmounts);

        emit Deposit(forAddr, share, amount);
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
        emit Withdraw(to, share, what);
    }

    function emergencyWithdraw() external onlyAdmin {
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
        uint256[] memory tokenAmounts = new uint256[](1);
        tokenAmounts[0] = IERC20(chefToken).balanceOf(address(this));
        if (tokenAmounts[0] > 0) {
            address[] memory tokens = new address[](1);
            tokens[0] = chefToken;
            (, , uint256 lpAmount) = tokenToLiquidity(lpToken, tokens, tokenAmounts, address(this));

            totalAmounts = totalAmounts.add(lpAmount);
            IERC20(lpToken).approve(address(chef), lpAmount);
            chef.deposit(chefPid, lpAmount);
        }
    }
}
