// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "./LPStorage.sol";
import "../admin/AdminableInit.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract LPableInit is Initializable {

    LPStorage storeLP;

    constructor() {}

    function initializeLiquidity(address _store) public virtual initializer {
        storeLP = LPStorage(_store);
    }

    function tokenToLiquidity(address pair, address[] memory tokens, uint256[] memory amountsDesired, address to) public returns (uint256, uint256, uint256) {
        return storeLP.tokenToLiquidity(pair, tokens, amountsDesired, to);
    }

}