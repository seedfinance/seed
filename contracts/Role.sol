// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;
import "./Storage.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface IRoleList {
    function roles() external view returns (address[] memory);

    function length() external view returns (uint256);

    function contains(address role_) external view returns (bool);

    function at(uint256 index_) external view returns (address);
}

contract RoleList is IRoleList {
    using EnumerableSet for EnumerableSet.AddressSet;

    Storage public store;
    EnumerableSet.AddressSet _roleSet;

    modifier onlyOwner() {
        require(store.isOwner(msg.sender), "Not owner");
        _;
    }

    constructor(Storage storage_) {
        store = storage_;
    }

    function add(address role_) external onlyOwner returns (bool) {
        return _roleSet.add(role_);
    }

    function remove(address role_) external onlyOwner returns (bool) {
        return _roleSet.remove(role_);
    }

    function roles() external view override returns (address[] memory results) {
        results = new address[](_roleSet.length());
        for (uint256 i = 0; i < _roleSet.length(); i++) {
            results[i] = _roleSet.at(i);
        }
    }

    function length() external view override returns (uint256) {
        return _roleSet.length();
    }

    function contains(address role_) external view override returns (bool) {
        return _roleSet.contains(role_);
    }

    function at(uint256 index_) external view override returns (address) {
        return _roleSet.at(index_);
    }
}
