// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

contract Storage {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not owner");
        _;
    }

    function setOwner(address owner_) external onlyOwner {
        require(owner_ != address(0), "new owner shouldn't be empty");
        owner = owner_;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
}
