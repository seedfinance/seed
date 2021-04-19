// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import './IERC20Storage.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC2612 is IERC20, IERC20Storage {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
