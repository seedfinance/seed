// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import './UserManagerStorage.sol';
import '../admin/AdminableInit.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';

contract UserManagerableInit is Initializable {
    UserManagerStorage userManagerStore;

    constructor() {}

    function initialize(address _userManagerStore) public virtual initializer {
        userManagerStore = UserManagerStorage(_userManagerStore);
    }
}
