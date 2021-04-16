// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IMasterChef.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/UniswapV2Library.sol";
import "../libraries/SwapLibrary.sol";
import "../interface/IStrategyManager.sol";

contract AutoInvestment is Ownable, Pausable {
    using SafeMath for uint256;
    event Deposit(address indexed forAddr, uint256 share);
    event Withdraw(address indexed forAddr, uint256 share);


    IStrategyManager public manager;

    IMasterChef public chef;
    address public chefToken;
    uint256 public chefPid;
    address public lpToken;

    uint256 public totalShares;
    mapping(address => uint256) public shares;

    constructor(
        IStrategyManager _manager,
        IMasterChef _chef,
        address _chefToken,
        uint256 _pid
    ) {
        manager = _manager;
        chef = _chef;
        (lpToken, , , ) = chef.poolInfo(_pid);
        require(lpToken != address(0), "lp token address mistake");
        chefToken = _chefToken;
        chefPid = _pid;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
         _unpause();
    }


    // deposit lp token
    function deposit(uint256 amount, address forAddr)
        external
        payable whenNotPaused
        returns (uint256 share)
    {
        doHardWork();
        uint256 totalAmounts = getTotalAmount();
        if (totalShares == 0 || totalAmounts == 0) {
            share = amount;
        } else {
            share = amount.mul(totalShares).div(totalAmounts);
        }
        totalShares = totalShares.add(share);
        shares[forAddr] = shares[forAddr].add(share);
        TransferHelper.safeTransferFrom(
            lpToken,
            msg.sender,
            address(this),
            amount
        );
        IERC20(lpToken).approve(address(chef), 0);
        IERC20(lpToken).approve(address(chef), amount);
        chef.deposit(chefPid, amount);

        emit Deposit(forAddr, share);
    }

    function emergencyWithdraw() external onlyOwner {
        chef.emergencyWithdraw(chefPid);
    }

    function doHardWork() public {
        if (paused()) {
            return;
        }
        // claim the earnings
        chef.withdraw(chefPid, 0);

        // reinvest
        uint256 swapAmount = IERC20(chefToken).balanceOf(address(this));
        (, , uint256 lpAmount) =
            SwapLibrary.swapToLpToken(manager, chefToken, lpToken, swapAmount, address(this));

        IERC20(lpToken).approve(address(chef), lpAmount);
        chef.deposit(chefPid, lpAmount);
    }

    function withdraw(address to, uint256 share) external {
        require(shares[msg.sender] >= share, "share not enough");

        doHardWork();
        // calc amount
        uint256 what = share.mul(getTotalAmount()).div(totalShares);
        uint256 withdrawAmount = what.sub(getLocalAmount());
        // if local not enough, withdraw from chef
        if (withdrawAmount > 0) {
            chef.withdraw(chefPid, withdrawAmount);
        }

        TransferHelper.safeTransfer(lpToken, to, what);
        shares[msg.sender] = shares[msg.sender].sub(share);
        totalShares = totalShares.sub(share);
        emit Withdraw(msg.sender, share);
    }

    function getTotalAmount() internal view returns (uint256 amount) {
        (amount, ) = IMasterChef(chef).userInfo(chefPid, address(this));
        amount = amount.add(IERC20(lpToken).balanceOf(address(this)));
    }

    function getLocalAmount() internal view returns (uint256 amount) {
        amount = amount.add(IERC20(lpToken).balanceOf(address(this)));
    }

}
