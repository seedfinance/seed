// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

interface IAccountMapper {
    function getAccountIndex(address) external view returns (address[] memory);

    function resolve(address) external returns (bool);

    function unresolve(address) external returns (bool);
}
