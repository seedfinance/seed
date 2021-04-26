// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import '../admin/AdminableInit.sol';
import '../interface/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract SwapStorage is AdminableInit {
    using SafeMath for uint256;

    struct PathItem {
        address[] pair;
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
        address[] calldata _path,
        address[] calldata _pair
    ) external onlyAdmin {
        require(_path.length >= 2, 'illegal path length');
        require(_path.length == _pair.length + 1, 'illegal pair length');
        require(_from == _path[0], 'The first token of the Uniswap route must be the from token');
        require(_to == _path[_path.length - 1], 'The last token of the Uniswap route must be the to token');
        PathItem memory item;
        item.path = _path;
        item.pair = _pair;
        pathes[_from][_to] = item;
    }

    function delPath(address _from, address _to) external onlyAdmin {
        delete pathes[_from][_to];
    }

    function pathFor(address _from, address _to) public view returns (PathItem memory) {
        return pathes[_from][_to];
    }
}
