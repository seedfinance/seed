// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import './StrategyManagerStorage.sol';
import '../admin/AdminableInit.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';

contract StrategyManagerableInit is Initializable {
    StrategyManagerStorage store;

    constructor() {}

    function initialize(address _store) public virtual initializer {
        store = StrategyManagerStorage(_store);
    }
    /*
    function pathFor(address _from, address _to) public view returns (address[] memory) {
        return store.pathFor(SWAP_MDX, _from, _to); 
    }

    function pathFor(bytes32 _swap, address _from, address _to) public view returns (address[] memory) {
        return store.pathFor(_swap, _from, _to); 
    }
    */
}
