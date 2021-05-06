// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import '@openzeppelin/contracts/proxy/Initializable.sol';
import './AdminStorage.sol';

contract AdminableInit is Initializable {
    AdminStorage public adminStore;

    constructor() {}

    function initializeAdmin(address _store) internal {
        require(_store != address(0), "new storage shouldn't be empty");
        adminStore = AdminStorage(_store);
    }

    modifier onlyAdmin() {
        require(adminStore.isAdmin(msg.sender), 'Not admin');
        _;
    }
}
