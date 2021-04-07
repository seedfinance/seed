// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "./FactoryStorage.sol";
import "./FactoryDelegator.sol";
import "../Retrieve.sol";
import "../../interfaces/IAccountMapper.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract FactoryDelegate is IAccountMapper, FactoryStorage, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    constructor() {}

    function initialize() public initializer {}

    function become(IFactoryDelegator delegator) public {
        // require(
        //     msg.sender == delegator.admin(),
        //     "delegate: only unitroller admin can change brains"
        // );
        delegator.acceptImplementation();
    }

    function resolve(address account) external override returns (bool) {
        require(register[msg.sender], "delegate: recoverd not registered");
        emit Resolved(account, msg.sender);
        return mapper[account].add(msg.sender);
    }

    function unresolve(address account) external override returns (bool) {
        require(register[msg.sender], "delegate: recoverd not registered");
        emit UnResolved(account, msg.sender);
        return mapper[account].remove(msg.sender);
    }

    function getAccountIndex(address one)
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory out = new address[](mapper[one].length());
        for (uint256 i = 0; i < mapper[one].length(); i++) {
            out[i] = mapper[one].at(i);
        }
        return out;
    }

    function create(address[] memory friends) external returns(address) {
        Retrieve retrieve = new Retrieve();
        register[address(retrieve)] = true;
        retrieve.initialize(address(this), msg.sender, friends);
        emit Created(address(retrieve));
        return address(retrieve);
    }
}
