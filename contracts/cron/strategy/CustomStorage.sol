// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../LPableInit.sol";
import "../../admin/AdminableInit.sol";


contract CustomStorage is AdminableInit {
    address public tokenReward; // pair reward address

    address  public pool; // mdx chef
    
    uint256 public pid;
    
    address public pair; // mdex pair, Address of LP contract address.
    
    address public factory; // mdx factory
    
    constructor() {}
    
    function initializeInvestment(
        address _storeAdmin,
        address _tokenReward,
        address _pool,
        uint256 _pid,
        address _pair,
        address _factory
        ) public initializer {
        AdminableInit.initializeAdmin(_storeAdmin);
        tokenReward = _tokenReward;
        pool = _pool;
        pid = _pid;
        pair = _pair;
        factory = _factory;
    }

    function setTokenReward(address _tokenReward) external onlyAdmin {
        tokenReward = _tokenReward;
    }

    function getTokenReward() public view returns (address) {
        return tokenReward;
    }
    function setPool(address _pool) external onlyAdmin {
        pool = _pool;
    }

    function getPool() public view returns (address) {
        return pool;
    }
    function setPid(uint256 _pid) external onlyAdmin {
        pid = _pid;
    }

    function getPid() public view returns (uint256) {
        return pid;
    }
    function setPair(address _pair) external onlyAdmin {
        pair = _pair;
    }

    function getPair() public view returns (address) {
        return pair;
    }
    function setFactory(address _factory) external onlyAdmin {
        factory = _factory;
    }

    function getFactory() public view returns (address) {
        return factory;
    }    
}