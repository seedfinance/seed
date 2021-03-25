// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) {
        _setupDecimals(decimals_);
        _mint(msg.sender, totalSupply_);
    }
}
