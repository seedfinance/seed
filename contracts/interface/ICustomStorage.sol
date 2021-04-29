// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

interface ICustomStorage {
    function getTokenReward() external view returns(address);
    function getPool() external view returns(address);
    function getPid() external view returns(uint256);
    function getPair() external view returns(address);
    function getFactory() external view returns(address);
}
