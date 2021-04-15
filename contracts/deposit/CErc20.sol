// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "../core/ERC2612.sol";
import "../interface/IVault.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CErc20 is ERC2612 {
    using SafeMath for uint256;
    IVault public underlying;

    constructor(address storage_, IVault underlying_)
        ERC2612(
            storage_,
            string(abi.encodePacked("d", underlying_.underlying().name())),
            string(abi.encodePacked("d", underlying_.underlying().symbol())),
            ERC20(underlying_.underlying()).decimals()
        )
    {
        underlying = underlying_;
    }

    function deposit(
        uint amount, 
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (value > 0) { //进行授权
            underlying.permit(
                msg.sender, address(this), value, deadline, v, r, s
            );
        }
        //得到sToken
        uint balanceBefore = underlying.balanceOf(address(this));
        underlying.transferFrom(msg.sender, address(this), amount);
        uint balanceAfter = underlying.balanceOf(address(this));
        require(amount == balanceAfter.sub(balanceBefore), "illegal transfer");
        //根据sToken得到underlying
        balanceBefore = underlying.underlying().balanceOf(address(this));
        underlying.approve(address(underlying), 0);
        underlying.approve(address(underlying), amount);
        underlying.withdraw(amount);
        balanceAfter = underlying.underlying().balanceOf(address(this));
        require(amount == balanceAfter.sub(balanceBefore), "illegal transfer");
        //分发给用户平台币
        uint exchangeRate = getExchangeRate();
        uint mintToken = amount.mul(1e18).div(exchangeRate);
        _mint(msg.sender, mintToken);
    }
    /*
    function withdraw(uint tokenAmount) external {
        require(balanceOf(msg.sender) >= tokenAmount, "influence balance");

    }
    */

    function getExchangeRate() public view returns (uint) {
        uint _totalSupply = totalSupply(); //dToken的数量
        if (_totalSupply == 0) {
            return 1e18;
        } else {
            uint balance = underlying.underlying().balanceOf(address(this)); 
            return balance.mul(1e18).div(_totalSupply);
        }
    }

}
