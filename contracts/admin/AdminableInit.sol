// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/proxy/Initializable.sol';
import './AdminStorage.sol';

contract AdminableInit is Initializable {
    AdminStorage public storeAdmin;

    constructor() {}

    function initializeAdmin(address _store) public virtual initializer {
        require(_store != address(0), "new storage shouldn't be empty");
        storeAdmin = AdminStorage(_store);
        
    }

    modifier onlyAdmin() {
        require(storeAdmin.isAdmin(msg.sender), "Not admin");
        _;
    }
}
