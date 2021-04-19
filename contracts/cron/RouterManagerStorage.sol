// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "../admin/AdminableInit.sol";
import "../interface/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RouterManagerStorage is AdminableInit {
    using SafeMath for uint256;

    mapping(address => address) pairToStrategy;

    constructor() {}

    function initialize(address _store) public initializer {
        AdminableInit.initializeAdmin(_store);
    }

    function strategyForPair(address _pair) external view returns (address) {
        return pairToStrategy[_pair];
    }

    function addStrategy(address _pair, address _strategy) external onlyAdmin {
        pairToStrategy[_pair] = _strategy;
    }
    
}
