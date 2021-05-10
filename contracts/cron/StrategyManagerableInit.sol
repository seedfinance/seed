// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import './StrategyManagerStorage.sol';
import '../admin/AdminableInit.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';

contract StrategyManagerableInit is Initializable {
    StrategyManagerStorage storeStrategy;

    constructor() {}

    function initializeStrategy(address _store) private {
        storeStrategy = StrategyManagerStorage(_store);
    }
}
