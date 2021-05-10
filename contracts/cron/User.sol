// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
//import "./BaseProxy.sol";
import './UserManagerableInit.sol';
import '../interface/IFactory.sol';
import '../interface/IERC2612.sol';
import '../admin/AdminableInit.sol';
import '../interface/IStrategy.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/proxy/UpgradeableProxy.sol';

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

    function getStrategyNum() external view returns(uint) {
        return strategys.length;
    }

    function getStrategy(uint _id) external view returns(address) {
        return strategys[_id - 1];
    }

    function createStrategy(uint256 _index, bytes memory data) external {
        require(factory.strategyExist(_index), "strategy not exist");
        UpgradeableProxy proxy = new UpgradeableProxy(factory.getStrategyById(_index), data);
        strategys.push(address(proxy));
    }
}
