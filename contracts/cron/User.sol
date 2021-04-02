// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
import "./UserManagerableInit.sol";
import "../admin/AdminableInit.sol";
import "../interface/IERC2612.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract User is UserManagerableInit {
    using SafeMath for uint256;

    address[] strategys;

    constructor() {}

    function initialize(address _store) public override initializer {
        AdminableInit.initialize(_store);    
    }


}
