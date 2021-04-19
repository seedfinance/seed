// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

interface IStrategyManager {
    struct PathItem {
        address router;
        address[] path;
    }

    function pathFor(address _from, address _to) external view returns (address, address[] memory);
}
