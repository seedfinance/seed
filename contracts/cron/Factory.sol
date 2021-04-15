// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
import "./User.sol";
import "../admin/AdminableInit.sol";
import "../interface/IERC2612.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Factory is AdminableInit  {
    using SafeMath for uint256;

    address[] strategyList;
    address[] userList;
    mapping (address => address) public userMap;
    UserManagerStorage userManagerStorage;

    function setUserManagerStorage(address _userManagerStorage) external onlyAdmin {
        userManagerStorage = UserManagerStorage(_userManagerStorage);
    }

    function getStrategyNum() external view returns(uint) {
        return strategyList.length;
    }

    function getStrategy(uint _idx) external view returns(address) {
        return strategyList[_idx];
    }

    function getUserNum() public view returns(uint) {
        return userList.length;
    }

    function userExist(address _user) public view returns (bool) {
        return userMap[_user] == address(0);
    }

    constructor() {}

    function initialize(address _store) public initializer {
        AdminableInit.initializeAdmin(_store);    
    }

    function createUser() public returns (address) {
        require(!userExist(msg.sender), "user already created");
        User user = new User(); 
        user.initialize(address(this), address(store), address(userManagerStorage));
        userMap[msg.sender] = address(user);
        userList.push(address(user));
        return address(user);
    }

}
