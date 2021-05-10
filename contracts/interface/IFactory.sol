// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import './IERC2612.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

interface IFactory {

    function strategyExist(uint256 _idx) external view returns (bool);

    function getStrategyNum() external view returns (uint256);

    function getStrategyById(uint256 _idx) external view returns (address);

    function getStrategyByAddress(address _strategy) external view returns (uint256);

    function getUserNum() external view returns (uint256);

    function userExist(address _user) external view returns (bool);

    function createUser() external returns (address);
}
