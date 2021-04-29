// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import "./CustomStorage.sol";
import "../../admin/AdminableInit.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract CustomableInit is Initializable {

    CustomStorage storeCustom;

    constructor() {}

    function initializeCustom(address _store) internal {
        storeCustom = CustomStorage(_store);
    }
}
