// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

contract AdminStorage {
    address public admin;
    address public pendingAdmin;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        admin = msg.sender;
        emit NewAdmin(address(0), admin);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not admin");
        _;
    }

    modifier onlyPendingAdmin() {
        require(isPendingAdmin(msg.sender), "Not pending admin");
        _;
    }

    function setPendingAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "new admin shouldn't be empty");
        require(admin_ != admin, "new admin is the save with old admin");
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = admin_;
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function acceptAdmin() external onlyPendingAdmin {
        address oldAdmin = admin;
        admin = pendingAdmin;
        emit NewAdmin(oldAdmin, admin);
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    function isPendingAdmin(address account) public view returns (bool) {
        return account == pendingAdmin;
    }
}
