// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract FactoryDelegator is Proxy, Initializable {
    event NewPendingImplementation(
        address oldPendingImplementation,
        address newPendingImplementation
    );
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);

    bytes32 internal constant _PENDING_IMPLEMENTATION_SLOT =
        0xb934901ebf3244f1659a9840042234c61640a585ab09b4f322ce284f3df86ee7;
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0xbbe9222478f202361cbba87e7b892281a77e39f09a27d85cf53e88a83f281f5c;
    bytes32 internal constant _PENDING_ADMIN_SLOT =
        0x983f9f63de388f21766bbb131a101c5cf87e8a4479cdcf0a03b4e329ae50ad59;
    bytes32 internal constant _ADMIN_SLOT =
        0xa93938cbabb3ecb20cf99f4af5d5811606ede8a321a410d8f4e9d6bbbdc6f5d9;

    uint256[50] private ______gap;

    constructor() {
        assert(
            _PENDING_IMPLEMENTATION_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.factory.pendingimplementation")) -
                        1
                )
        );
        assert(
            _IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.factory.implementation")) - 1)
        );
        assert(
            _PENDING_ADMIN_SLOT ==
                bytes32(uint256(keccak256("eip1967.factory.pendingadmin")) - 1)
        );
        assert(
            _ADMIN_SLOT ==
                bytes32(uint256(keccak256("eip1967.factory.admin")) - 1)
        );
        setAddress(_ADMIN_SLOT, msg.sender);
    }

    modifier onlyAdmin() {
        require(admin() == msg.sender, "Factory: caller is not the owner");
        _;
    }

    function initialize(address _logic, bytes memory _data) public initializer {
        require(
            Address.isContract(_logic),
            "Factory: new implementation is not a contract"
        );
        setAddress(_IMPLEMENTATION_SLOT, _logic);
        Address.functionDelegateCall(
            _logic,
            abi.encodeWithSignature("initialize()", _data)
        );
    }

    function setPendingImplementation(address newPendingImplementation)
        public
        onlyAdmin
    {
        require(
            Address.isContract(newPendingImplementation),
            "Factory: new implementation is not a contract"
        );
        address oldPendingImplementation =
            getAddress(_PENDING_IMPLEMENTATION_SLOT);
        setAddress(_PENDING_IMPLEMENTATION_SLOT, newPendingImplementation);
        emit NewPendingImplementation(
            oldPendingImplementation,
            newPendingImplementation
        );
    }

    function acceptImplementation() public {
        require(
            msg.sender != address(0) && msg.sender == pendingImplementation(),
            "Factory: unauthorized Implementation"
        );
        address oldPendingImplementation = pendingImplementation();
        address oldImplementation = Implementation();
        address newPendingImplementation = address(0);
        address newImplementation = oldPendingImplementation;
        setAddress(_IMPLEMENTATION_SLOT, oldPendingImplementation);
        setAddress(_PENDING_IMPLEMENTATION_SLOT, newPendingImplementation);
        emit NewImplementation(oldImplementation, newImplementation);
        emit NewPendingImplementation(
            oldPendingImplementation,
            newPendingImplementation
        );
    }

    function setPendingAdmin(address newPendingAdmin) public onlyAdmin {
        address oldPendingAdmin = getAddress(_PENDING_ADMIN_SLOT);
        setAddress(_PENDING_ADMIN_SLOT, newPendingAdmin);
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() public {
        require(
            msg.sender != address(0) && msg.sender == pendingAdmin(),
            "Factory: unauthorized admin"
        );
        address oldPendingAdmin = pendingAdmin();
        address oldAdmin = admin();
        address newPendingAdmin = address(0);
        address newAdmin = oldPendingAdmin;
        setAddress(_PENDING_ADMIN_SLOT, newPendingAdmin);
        setAddress(_ADMIN_SLOT, newAdmin);

        emit NewAdmin(oldAdmin, newAdmin);
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function pendingImplementation() public view returns (address str) {
        return getAddress(_PENDING_IMPLEMENTATION_SLOT);
    }

    function Implementation() public view returns (address str) {
        return getAddress(_IMPLEMENTATION_SLOT);
    }

    function pendingAdmin() public view returns (address str) {
        return getAddress(_PENDING_ADMIN_SLOT);
    }

    function admin() public view returns (address str) {
        return getAddress(_ADMIN_SLOT);
    }

    function _implementation() internal view override returns (address) {
        return getAddress(_IMPLEMENTATION_SLOT);
    }

    function setAddress(bytes32 slot, address _address) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function getAddress(bytes32 slot) private view returns (address str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }
}
