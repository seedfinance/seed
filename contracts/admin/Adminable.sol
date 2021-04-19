// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import './AdminStorage.sol';

contract Adminable {
    AdminStorage public store;

    constructor(address _store) {
        require(_store != address(0), "new storage shouldn't be empty");
        store = AdminStorage(_store);
    }

    modifier onlyAdmin() {
        require(store.isAdmin(msg.sender), 'Not admin');
        _;
    }

    function isAdmin(address from) external view returns (bool) {
        return store.isAdmin(from);
    }

    function admin() external view returns (address) {
        return store.admin();
    }
}
