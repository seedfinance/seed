// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

interface ISwapStorage {
    struct PathItem {
        address[] pair;
        address[] path;
    }

    function pathFor(address _from, address _to) external view returns (PathItem memory);
}
