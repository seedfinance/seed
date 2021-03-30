// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

interface IVault {

    function deposit(uint256 amount) external payable;

    function withdraw(uint256 amount) external;

}
