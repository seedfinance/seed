// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import './LPStorage.sol';
import '../admin/AdminableInit.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';

contract LPableInit is Initializable {
    LPStorage storeLP;

    constructor() {}

    function initializeLiquidity(address _store) internal {
        storeLP = LPStorage(_store);
    }

    function tokenToLiquidity(
        address pair,
        address[] memory tokens,
        uint256[] memory amountsDesired,
        address to
    )
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        for (uint256 i; i < tokens.length; ++i) {
            IERC20(tokens[i]).approve(address(storeLP), amountsDesired[i]);
        }
        return storeLP.tokenToLiquidity(pair, tokens, amountsDesired, to);
    }
}
