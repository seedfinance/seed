// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

contract AdminStorage {
    address public admin;
    mapping(address => bool) public workers;
    uint workerNum;
    address public pendingAdmin;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    event AddWorker(address worker, uint oldNum, uint currentNum);

    event DelWorker(address worker, uint oldNum, uint currentNum);

    constructor() {
        admin = msg.sender;
        workerNum = 0;
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

    modifier onlyAdminOrWorkers() {
        require(isAdmin(msg.sender) || isWorker(msg.sender), "Not admin or worker");
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

    function addWorker(address account) external onlyAdmin {
        uint oldNum = workerNum;
        if (!workers[account]) {
            workers[account] = true;
            workerNum += 1;
        }
        emit AddWorker(account, oldNum, workerNum);
    }

    function removeWorker(address account) external onlyAdmin {
        uint oldNum = workerNum;
        if (workers[account]) {
            workers[account] = false;
            workerNum -= 1;
        }
        emit DelWorker(account, oldNum, workerNum);
    }

    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    function isPendingAdmin(address account) public view returns (bool) {
        return account == pendingAdmin;
    }

    function isWorker(address account) public view returns (bool) {
        return workers[account];
    }
}
