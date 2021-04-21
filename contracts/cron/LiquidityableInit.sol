// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "./LiquidityStorage.sol";
import "../admin/AdminableInit.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract LiquidityableInit is Initializable {

    LiquidityStorage storeLiquidity;

    constructor() {}

    function initializeLiquidity(address _store) internal {
        storeLiquidity = LiquidityStorage(_store);
    }

    function swapToLpToken(address token, address pair, uint256 amount, address to) public
        returns (
            uint256 exactAmountA,
            uint256 exactAmountB,
            uint256 liquidity
        )
    {
        return storeLiquidity.swapToLpToken(token, pair, amount, to);
    }
}
