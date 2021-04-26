// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
import './User.sol';
import 'hardhat/console.sol';
import '../admin/AdminableInit.sol';
import '../interface/IERC2612.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Factory is AdminableInit {
    using SafeMath for uint256;

    address[] public strategyList;
    mapping(address => uint256) strategyMap;
    address[] public userList;
    mapping(address => address) public userMap;
    UserManagerStorage public userManagerStorage;

    function setUserManagerStorage(address _userManagerStorage) external onlyAdmin {
        userManagerStorage = UserManagerStorage(_userManagerStorage);
    }

    function getStrategyNum() external view returns (uint256) {
        return strategyList.length;
    }

    function addStrategy(address _strategy) external onlyAdmin returns (uint256) {
        require(strategyMap[_strategy] == 0, 'strategy already exists');
        strategyList.push(_strategy);
        strategyMap[_strategy] = strategyList.length;
    }

    function delStrategy(uint256 _idx) external onlyAdmin returns (address) {
        require(_idx <= strategyList.length, 'strategy not exist');
        address strategy = strategyList[_idx - 1];
        require(strategyMap[strategy] != 0, 'strategy not exist');
        delete strategyMap[strategy];
        return strategy;
    }

    function strategyExist(uint256 _idx) public view returns (bool) {
        if (_idx > strategyList.length) {
            return false;
        }
        address strategy = strategyList[_idx - 1];
        if (strategyMap[strategy] == 0) {
            return false;
        }
        return true;
    }

    function getStrategyById(uint256 _idx) external view returns (address) {
        require(strategyExist(_idx), 'strategy not exists');
        return strategyList[_idx - 1];
    }

    function getStrategyByAddress(address _strategy) external view returns (uint256) {
        require(strategyMap[_strategy] != 0, 'strategy not exist');
        return strategyMap[_strategy];
    }

    function getUserNum() public view returns (uint256) {
        return userList.length;
    }

    function userExist(address _user) public view returns (bool) {
        return userMap[_user] != address(0);
    }

    constructor() {}

    function initialize(address _store, address _userManagerStorage) public initializer {
        AdminableInit.initializeAdmin(_store);
        userManagerStorage = UserManagerStorage(_userManagerStorage);
    }

    function createUser() public returns (address) {
        require(!userExist(msg.sender), 'user already created');
        User user = new User();
        user.initialize(address(this), address(storeAdmin), address(userManagerStorage));
        userMap[msg.sender] = address(user);
        userList.push(address(user));
        return address(user);
    }
}
