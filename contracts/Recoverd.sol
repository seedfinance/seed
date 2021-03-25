// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract Recoverd {
    using SafeMath for uint256;

    string public constant name = "Recoverd";
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the ballot execute used by the contract
    bytes32 public constant CHANGEOWNER_TYPEHASH =
        keccak256("ChangeOwner(address target,uint256 nonce,uint eta)");

    address public owner;
    address[2] public friend;
    mapping(address => uint256) nonce;

    constructor(address guy1, address guy2) {
        owner = msg.sender;
        friend[0] = guy1;
        friend[1] = guy2;
    }

    function changeOwner(
        address[2] calldata newOwner_,
        uint256[2] calldata nonce_,
        uint256[2] calldata eta_,
        uint8[2] calldata v_,
        bytes32[2] calldata r_,
        bytes32[2] calldata s_
    ) external {
        require(
            newOwner_[0] == newOwner_[1] && newOwner_[0] != address(0),
            "invalid new owner"
        );
        _verifySigs(newOwner_[0], nonce_[0], eta_[0], v_[0], r_[0], s_[0]);
        _verifySigs(newOwner_[1], nonce_[1], eta_[1], v_[1], r_[1], s_[1]);
        owner = newOwner_[0];
    }

    function callFunc(
        address target_,
        uint256 value_,
        bytes memory data_
    ) external payable returns (bytes memory) {
        require(msg.sender == owner, "dev: wut?");

        (bool success, bytes memory returnData) =
            target_.call{value: value_}(data_);
        require(success, "Transaction execution reverted.");

        return returnData;
    }

    // fallback() external payable {

    //     assembly {
    //         let free_ptr := mload(0x40)
    //         calldatacopy(free_ptr, 0, calldatasize())
    //         /* We must explicitly forward ether to the underlying contract as well. */
    //         let result := call(gas(), sload(0), callvalue(), free_ptr, calldatasize(), 0, 0)
    //         returndatacopy(free_ptr, 0, returndatasize())

    //         if iszero(result) { revert(free_ptr, returndatasize()) }
    //         return(free_ptr, returndatasize())
    //     }
    // }

    receive() external payable {}

    function _verifySigs(
        address newOwner_,
        uint256 nonce_,
        uint256 eta_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal {
        bytes32 domainSeparator =
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    getChainId(),
                    address(this)
                )
            );
        bytes32 structHash =
            keccak256(
                abi.encode(CHANGEOWNER_TYPEHASH, newOwner_, nonce_, eta_)
            );
        bytes32 digest =
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );

        address signatory = ecrecover(digest, v_, r_, s_);

        require(signatory != address(0), "invalid signature");
        require(
            signatory == friend[0] || signatory == friend[1],
            "signatory not in list"
        );
        require(eta_ > block.timestamp, "signature expired");
        require(nonce_ == nonce[signatory].add(1), "invalid nonce");
        nonce[signatory] = nonce[signatory].add(1);
    }

    // get current chain id
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
