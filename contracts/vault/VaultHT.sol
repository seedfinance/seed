// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import '../core/ERC2612.sol';
import '../interface/IVault.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract VaultHT is Adminable, ERC2612 {
    using SafeMath for uint256;
    ERC20 public underlying; //WHT

    constructor(address storage_, ERC20 underlying_)
        ERC2612(
            storage_,
            string(abi.encodePacked('s', underlying_.name())),
            string(abi.encodePacked('s', underlying_.symbol())),
            underlying_.decimals()
        )
    {
        underlying = underlying_;
    }

    function deposit(uint256 amount) external payable {
        require(amount == msg.value, 'illegal HT amount');
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        msg.sender.transfer(amount);
    }
}
