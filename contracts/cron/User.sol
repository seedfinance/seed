// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
//import "./BaseProxy.sol";
import './UserManagerableInit.sol';
import '../interface/IFactory.sol';
import '../interface/IERC2612.sol';
import '../admin/AdminableInit.sol';
import '../interface/IStrategy.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract User is AdminableInit, UserManagerableInit {
    using SafeMath for uint256;

    IFactory factory;
    address[] strategys;

    constructor() {}

    function initialize(
        address _factory,
        address _adminStore,
        address _userManagerStorage
    ) external initializer {
        factory = IFactory(_factory);
        AdminableInit.initializeAdmin(_adminStore);
        UserManagerableInit.initialize(_userManagerStorage);
    }

    function createStrategy(uint256 index, bytes memory data) external {
        /*
        require(index < factory.getStrategyNum(), "illegal index");
        BaseProxy proxy = new BaseProxy(address(store), factory.getStrategy(index), false);
        IStrategy(address(proxy)).initialize(address(store), data);
        strategys.push(address(proxy));
        */
    }
}
