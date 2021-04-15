// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import "./IERC2612.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStrategy {

    function initialize(address _store, bytes memory _data) external;

}
