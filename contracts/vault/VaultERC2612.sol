// SPDX-License-Identifier: MIT

pragma solidity 0.7.2;

import "../core/ERC2612.sol";
import "../interface/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract VaultERC2612 is Adminable, ERC2612, IVault {
    using SafeMath for uint256;
    ERC20 public underlying;

    constructor(address storage_, ERC20 underlying_) 
        ERC2612(
            storage_,
            string(abi.encodePacked("s", underlying_.name())),
            string(abi.encodePacked("s", underlying_.symbol())),
            underlying_.decimals()
        )
    {
        underlying = underlying_;
    }

    function deposit(uint256 amount) external payable override {
        require (msg.value == 0, "contract donot accept HT");
        uint balanceBefore = underlying.balanceOf(address(this));
        underlying.transferFrom(msg.sender, address(this), amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");
        uint balanceAfter = underlying.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        amount = balanceAfter.sub(balanceBefore);
        _mint(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override {
        uint balanceBefore = underlying.balanceOf(address(this));
        underlying.transfer(msg.sender, amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");
        uint balanceAfter = underlying.balanceOf(address(this));
        require(balanceBefore.sub(balanceAfter) == amount, "TOKEN_TRANSFER_IN_OVERFLOW");
        _burn(msg.sender, amount);

    }

}
