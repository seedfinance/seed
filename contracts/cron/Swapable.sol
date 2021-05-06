// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import './SwapStorage.sol';
import '../admin/AdminableInit.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';

contract Swapable {
    SwapStorage swapStore;

    constructor(address _store) {
        require(_store != address(0), "new storage shouldn't be empty");
        swapStore = SwapStorage(_store);
    }

    function pathFor(address _from, address _to) public view returns (SwapStorage.PathItem memory) {
        return swapStore.pathFor(_from, _to);
    }

}
