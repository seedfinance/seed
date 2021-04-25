// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Pair.sol";

interface ISwapStorage {

    struct PathItem {
        address[] pair;
        address[] path;
    }

    function pathFor(address _from, address _to) external view returns (PathItem memory);

}
