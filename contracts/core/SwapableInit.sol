// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import './SwapStorage.sol';
import './AdminableInit.sol';
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

}
