// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import '../admin/AdminableInit.sol';
import '../interface/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract StrategyManagerStorage is AdminableInit {
    using SafeMath for uint256;

    struct PathItem {
        address router;
        address[] path;
    }

    mapping(address => mapping(address => PathItem)) pathes;

    constructor() {}

    function initialize(address _store) public initializer {
        AdminableInit.initializeAdmin(_store);
    }

    function setPath(
        address _from,
        address _to,
        address[] memory _path,
        address _router
    ) external onlyAdmin {
        require(_from == _path[0], 'The first token of the Uniswap route must be the from token');
        require(_to == _path[_path.length - 1], 'The last token of the Uniswap route must be the to token');
        PathItem memory item;
        item.path = _path;
        item.router = _router;
        pathes[_from][_to] = item;
    }

    function delPath(address _from, address _to) external onlyAdmin {
        delete pathes[_from][_to];
    }

    function pathFor(address _from, address _to) public view returns (PathItem memory) {
        return pathes[_from][_to];
    }

    function swap(
        address _fromToken,
        address _toToken,
        uint256 amount
    ) external returns (uint256) {
        uint256 balanceBefore = IERC20(_fromToken).balanceOf(address(this));
        IERC20(_fromToken).transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(_fromToken).balanceOf(address(this));
        require(balanceAfter.sub(balanceBefore) == amount, 'illegal token transfer');
        PathItem memory item = pathFor(_fromToken, _toToken);
        uint256[] memory amounts = IUniswapV2Router02(item.router).swapExactTokensForTokens(amount, 0, item.path, msg.sender, block.timestamp);
        return amounts[amounts.length - 1];
    }
}
