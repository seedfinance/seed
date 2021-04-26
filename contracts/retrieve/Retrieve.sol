// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
import '../interface/IAccountMapper.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';

contract Retrieve is Initializable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum ExecuteType {ChangeExecutor, AddFriend, RemoveFriend}
    enum ProposalState {Active, Succeeded, Expired, Executed}

    struct Proposal {
        uint256 id;
        ExecuteType executeType;
        address target;
        address proposer;
        uint256 eta;
        uint256 forVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    IAccountMapper public mapper;
    string public constant name = 'RetrieveV1';

    uint256 public proposalCount;
    address public pendingExecutor;
    address public executor;

    EnumerableSet.AddressSet pendingFriends;
    EnumerableSet.AddressSet friends;

    Proposal[] public proposals;
    mapping(address => uint256) public latestProposalIds;
    bytes32 public constant DOMAIN_TYPEHASH = keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256('Ballot(uint256 proposalId)');

    event AddPendingFriend(address pendingFriend);
    event RemovePendingFriend(address pendingFriend);
    event AcceptedFriend(address friend);
    event RemoveFriend(address friend);
    event ChangePendingExecutor(address pendingExecutor);
    event ExecutorChanged(address oldExecutor, address executor);
    event ProposalCreated(uint256 id, address proposer, address target, uint256 type_, uint256 eta);
    event ProposalExecuted(uint256 proposalId);
    event VoteCast(address voter, uint256 proposalId);

    constructor() {
        proposals.push();
    }

    function initialize(
        address accountMapper_,
        address executor_,
        address[] memory pendingFriends_
    ) external initializer {
        for (uint256 i = 0; i < pendingFriends_.length; i++) {
            pendingFriends.add(pendingFriends_[i]);
        }
        mapper = IAccountMapper(accountMapper_);
        setExecutor(executor_);
    }

    function retrieveAvailable() public view returns (bool) {
        return friends.length() > 2;
    }

    function quorumVotes() public view returns (uint256) {
        if (!retrieveAvailable()) {
            return 0;
        }
        return (friends.length().add(1)) / 2;
    }

    function getPendingFriends() external view returns (address[] memory) {
        address[] memory out = new address[](pendingFriends.length());
        for (uint256 i = 0; i < pendingFriends.length(); i++) {
            out[i] = pendingFriends.at(i);
        }
        return out;
    }

    function getFriends() external view returns (address[] memory) {
        address[] memory out = new address[](friends.length());
        for (uint256 i = 0; i < friends.length(); i++) {
            out[i] = friends.at(i);
        }
        return out;
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, 'state: invalid proposal id');
        Proposal storage proposal = proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp > proposal.eta) {
            return ProposalState.Expired;
        } else if (proposal.forVotes < quorumVotes()) {
            return ProposalState.Active;
        } else {
            return ProposalState.Succeeded;
        }
    }

    function addPendingFriend(address guy) internal returns (bool) {
        emit AddPendingFriend(guy);
        return pendingFriends.add(guy);
    }

    function removePendingFriend(address guy) internal returns (bool) {
        emit RemovePendingFriend(guy);
        return pendingFriends.remove(guy);
    }

    function removeFriend(address guy) internal returns (bool) {
        emit RemoveFriend(guy);
        mapper.unresolve(guy);
        return friends.remove(guy);
    }

    function setExecutor(address guy) internal returns (bool) {
        executor = guy;
        mapper.resolve(guy);
    }

    function changePendingExecutor(address guy) internal returns (bool) {
        pendingExecutor = guy;
        emit ChangePendingExecutor(guy);
        return true;
    }

    function acceptFriend() external {
        require(pendingFriends.contains(msg.sender), 'address not in pending address');
        require(!friends.contains(msg.sender), 'address has already been list');
        pendingFriends.remove(msg.sender);
        friends.add(msg.sender);
        mapper.resolve(msg.sender);
        emit AcceptedFriend(msg.sender);
    }

    function acceptExecutor() external {
        require(msg.sender == pendingExecutor, 'acceptExecutor: pendingExecutor mismatch');
        pendingExecutor = address(0);
        address oldExecutor = executor;
        mapper.unresolve(oldExecutor);
        setExecutor(msg.sender);
        emit ExecutorChanged(oldExecutor, executor);
    }

    function propose(
        address target_,
        uint256 executeType_,
        uint256 eta_
    ) external returns (uint256) {
        require(quorumVotes() > 0, 'propose: quorumVotes not enough');
        require(block.timestamp < eta_, 'eta: latest block.timestamp');

        require(target_ != address(0), 'propose: target invalid');
        require(target_ != executor, 'propose: target invalid');

        Proposal storage newProposal = proposals.push();
        newProposal.id = ++proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.target = target_;
        newProposal.executeType = ExecuteType(executeType_);
        newProposal.eta = eta_;
        newProposal.forVotes = 0;
        newProposal.executed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        emit ProposalCreated(newProposal.id, msg.sender, target_, executeType_, eta_);
        return newProposal.id;
    }

    function castVote(uint256 proposalId) external {
        return _castVote(msg.sender, proposalId);
    }

    function castVoteBySig(
        uint256 proposalId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'castVoteBySig: invalid signature');
        return _castVote(signatory, proposalId);
    }

    function _castVote(address voter, uint256 proposalId) internal {
        require(friends.contains(voter), '_castVote: voter not in the list');
        require(state(proposalId) == ProposalState.Active, '_castVote: voting is closed');
        Proposal storage proposal = proposals[proposalId];
        require(proposal.hasVoted[voter] == false, '_castVote: voter already voted');
        proposal.forVotes = proposal.forVotes.add(1);
        proposal.hasVoted[voter] = true;
        emit VoteCast(voter, proposalId);
    }

    function execute(uint256 proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, 'execute: proposal can only be executed if it is succeeded');
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        if (proposal.executeType == ExecuteType.ChangeExecutor) {
            changePendingExecutor(proposal.target);
        } else if (proposal.executeType == ExecuteType.AddFriend) {
            addPendingFriend(proposal.target);
        } else if (proposal.executeType == ExecuteType.RemoveFriend) {
            removeFriend(proposal.target);
        }

        emit ProposalExecuted(proposalId);
    }

    function callFunc(
        address target_,
        uint256 value_,
        bytes memory data_
    ) external payable returns (bytes memory) {
        require(msg.sender == executor, 'dev: wut?');
        require(target_ != address(mapper), 'dev: wut?');

        (bool success, bytes memory returnData) = target_.call{value: value_}(data_);
        require(success, 'Transaction execution reverted.');

        return returnData;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    receive() external payable {}
}
