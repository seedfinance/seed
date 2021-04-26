// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import './SwapStorage.sol';
import '../admin/AdminableInit.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';

contract SwapableInit is Initializable {
    SwapStorage storeSwap;

    constructor() {}

    function initializeSwap(address _store) internal {
        storeSwap = SwapStorage(_store);
    }

    function pathFor(address _from, address _to) public view returns (SwapStorage.PathItem memory) {
        return storeSwap.pathFor(_from, _to);
    }

    function swap(
        address _fromToken,
        address _toToken,
        uint256 amount
    ) public returns (uint256) {
        /*
        IERC20(_fromToken).approve(address(storeSwap), amount);
        return storeSwap.swap(_fromToken, _toToken, amount);
        */
    }

    function swapForExact(
        address _fromToken,
        address _toToken,
        uint256 amount,
        uint256 maxAmount
    ) public returns (uint256) {
        /*
        IERC20(_fromToken).approve(address(storeSwap), maxAmount);
        return storeSwap.swapForExact(_fromToken, _toToken, amount, maxAmount);
        */
    }

    function getAmountsOut(
        address _fromToken,
        address _toToken,
        uint256 amount
    ) public returns (uint256) {
        /*
        return storeSwap.getAmountsOut(_fromToken, _toToken, amount);
        */
    }
}
