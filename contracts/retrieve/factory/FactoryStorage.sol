// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;
import '@openzeppelin/contracts/utils/EnumerableSet.sol';

abstract contract FactoryStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Created(address);
    event Resolved(address, address);
    event UnResolved(address, address);

    mapping(address => EnumerableSet.AddressSet) internal mapper;
    mapping(address => bool) public register;
}