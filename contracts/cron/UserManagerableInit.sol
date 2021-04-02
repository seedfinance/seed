// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import "./UserManagerStorage.sol";
import "../admin/AdminableInit.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract UserManagerableInit is AdminableInit {

    constructor() {}

    function initialize(address _store) public virtual override initializer {
        AdminableInit.initialize(_store);
    }

    function setMinFee(uint newMinFee) external onlyAdmin {
        UserManagerStorage(address(store)).setMinFee(newMinFee);
    }

    function setAdditionFee(uint newAdditionFee) external onlyAdmin {
        UserManagerStorage(address(store)).setAdditionFee(newAdditionFee);
    }

    function setFeeReceiver(address newFeeReceiver) external onlyAdmin {
        UserManagerStorage(address(store)).setFeeReceiver(newFeeReceiver);
    }

}
