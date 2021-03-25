// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;
import "./ERC2612.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract VaultERC2612 is ERC2612 {
    using SafeMath for uint256;

    ERC20 public token;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(
        Storage storage_,
        ERC20 token_,
        IRoleList roleList_
    )
        ERC2612(
            storage_,
            string(abi.encodePacked("SEED_", token_.name())),
            string(abi.encodePacked("S", token_.symbol())),
            token_.decimals(),
            roleList_
        )
    {
        token = token_;
    }

    function deposit(uint256 wad) external {
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), wad);
        _mint(msg.sender, wad);
        emit Deposit(msg.sender, wad);
    }

    function withdraw(uint256 wad) external {
        _burn(msg.sender, wad);
        SafeERC20.safeTransfer(token, msg.sender, wad);
        emit Withdrawal(msg.sender, wad);
    }
}
