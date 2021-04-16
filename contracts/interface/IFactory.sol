// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import "./IERC2612.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFactory {

    function getStrategyNum() external view returns(uint);

    function getStrategy(uint _idx) external view returns(address);

    function getUserNum() external view returns(uint);

    function userExist(address _user) external view returns (bool);

    function createUser() external returns (address);

}