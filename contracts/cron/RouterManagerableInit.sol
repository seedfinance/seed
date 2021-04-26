// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import './RouterManagerStorage.sol';
import '../admin/AdminableInit.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';

contract RouterManagerableInit is Initializable {
    RouterManagerStorage routerStore;

    constructor() {}

    function initialize(address _store) private {
        routerStore = RouterManagerStorage(_store);
    }

    function strategyForPair(address _pair) external view returns (address) {
        return routerStore.strategyForPair(_pair);
    }
}
