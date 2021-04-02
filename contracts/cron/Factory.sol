// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
import "./User.sol";
import "../admin/AdminableInit.sol";
import "../interface/IERC2612.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Factory is AdminableInit {
    using SafeMath for uint256;

    address[] strategys;
    mapping (address => address) public users;

    function getStrategyNum() public view returns(uint) {
        return strategys.length;
    }

    constructor() {}

    function initialize(address _store) public override initializer {
        AdminableInit.initialize(_store);    
    }

    function createUser() public {
        require(users[msg.sender] == address(0), "user already created");
        User user = new User(); 
        users[msg.sender] = address(user);
        uint len = strategys.length;
        strategys[len] = address(user);
    }

}
