// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import './AdminStorage.sol';

contract Adminable {
    AdminStorage public adminStorage;

    constructor(address _store) {
        require(_store != address(0), "new storage shouldn't be empty");
        adminStorage = AdminStorage(_store);
    }

    modifier onlyAdmin() {
        require(adminStorage.isAdmin(msg.sender), 'Not admin');
        _;
    }

    function isAdmin(address from) external view returns (bool) {
        return adminStorage.isAdmin(from);
    }

    function admin() external view returns (address) {
        return adminStorage.admin();
    }

    function getAdminStorage() internal view returns (AdminStorage) {
        return adminStorage;
    }
}
