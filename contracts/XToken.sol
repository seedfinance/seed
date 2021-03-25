// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "./ERC2612.sol";
import "./VaultERC2612.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract XTokenBar is ERC2612 {
    using SafeMath for uint256;
    VaultERC2612 public sToken;

    // Define the XToken contract
    constructor(
        Storage storage_,
        VaultERC2612 _sToken,
        IRoleList roleList_
    )
        ERC2612(
            storage_,
            string(abi.encodePacked("X", _sToken.token().name())),
            string(abi.encodePacked("X", _sToken.token().symbol())),
            _sToken.token().decimals(),
            roleList_
        )
    {
        sToken = _sToken;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 _amount) public {
        // Gets the amount of Sushi locked in the contract
        uint256 totalSToken = sToken.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply;
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSToken == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalSToken);
            _mint(msg.sender, what);
        }
        // Lock the Sushi in the contract
        sToken.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Sushi and burns xSushi
    function leave(uint256 _share) public {
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply;
        // Calculates the amount of Sushi the xSushi is worth
        uint256 what =
            _share.mul(sToken.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        sToken.transfer(msg.sender, what);
    }
}
