// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;
import "./Role.sol";
import "./ERC2612.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract VaultEther is ERC2612 {
    using SafeMath for uint256;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(Storage storage_, IRoleList roleList_)
        ERC2612(storage_, "SEED_ETHER", "SETH", 18, roleList_)
    {
        approveWhitelist = roleList_;
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) external {
        require(balanceOf[msg.sender] >= wad, "");
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}
