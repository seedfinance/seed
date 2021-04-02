// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import "./IERC2612.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IVault is IERC2612 {

    function deposit(uint256 amount) external payable;

    function withdraw(uint256 amount) external;

    function underlying() external view returns(ERC20);
}
