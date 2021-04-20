// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "./SwapableInit.sol";
import "./LPBuilder.sol";
import "../libraries/UniswapV2Library.sol";
import "../libraries/TransferHelper.sol";
import "../admin/AdminableInit.sol";
import "../interface/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LPStorage is AdminableInit {
    using SafeMath for uint256;

    mapping(address => address) builders;

    constructor() {}

    function initializeLiquidity(address _storeAdmin) public initializer {
        AdminableInit.initializeAdmin(_storeAdmin);
    }

    function setBuilder(address _pair, address _builder) external onlyAdmin {
        builders[_pair] = _builder;
    }

    function getBuilder(address _pair) public view returns (address) {
        return builders[_pair];
    }

    function tokenToLiquidity(address pair, address[] calldata tokens, uint256[] calldata amountsDesired, address to) external returns (uint256, uint256, uint256) {
        LPBuilder(builders[pair]).tokenToLiquidity(tokens, amountsDesired, to);
    }


}
