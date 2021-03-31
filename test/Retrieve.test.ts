import { deployments, ethers, getNamedAccounts } from "hardhat"
import { expect } from "chai"

describe("Retrieve", () => {
  before(async function () {
    this.ChangeExecutor = 0
    this.AddFriend = 1
    this.RemoveFriend = 2
    this.chainId = (await ethers.provider.getNetwork()).chainId

    this.FactoryDelegator = await ethers.getContractFactory("FactoryDelegator")
    this.FactoryDelegate = await ethers.getContractFactory("FactoryDelegate")
    this.signers = await ethers.getSigners()
    ;[this.alice, this.bob, this.carol, this.dave, this.eve, this.isaac] = await ethers.getSigners()

    console.log("alice:", this.alice.address)
    console.log("bob:", this.bob.address)
    console.log("carol:", this.carol.address)
    console.log("dave:", this.dave.address)
    console.log("eve:", this.eve.address)
    console.log("isaac:", this.isaac.address)

    this.factoryDelegate = await this.FactoryDelegate.deploy()
    await this.factoryDelegate.deployed()
    this.factoryDelegator = await this.FactoryDelegator.deploy()
    await this.factoryDelegator.deployed()
    console.log("deployed factoryDelegate", this.factoryDelegate.address)
    console.log("deployed factoryDelegator", this.factoryDelegator.address)
    this.factoryDelegator.initialize(this.factoryDelegate.address, "0x")
    this.delegate = await ethers.getContractAt("FactoryDelegate", this.factoryDelegator.address)
  })

  beforeEach(async function () {
    let tx = await (await this.delegate.connect(this.bob).create([this.carol.address, this.dave.address, this.eve.address])).wait()
    let retrieve = tx.events?.filter((x) => {
      return x.event == "Created"
    })[0].args[0]
    this.retrieveContract = await ethers.getContractAt("Retrieve", retrieve)
    await this.retrieveContract.connect(this.carol).acceptFriend()
    await this.retrieveContract.connect(this.dave).acceptFriend()
    await this.retrieveContract.connect(this.eve).acceptFriend()
  })

  it("Retrieve available", async function () {
    expect(await this.retrieveContract.executor()).to.equal(this.bob.address)
    let friends = await this.retrieveContract.getFriends()
    expect(friends).to.have.lengthOf(3)
    expect(friends).to.include(this.carol.address)
    expect(friends).to.include(this.dave.address)
    expect(friends).to.include(this.eve.address)

    expect(await this.retrieveContract.retrieveAvailable()).to.be.true
    expect(await this.retrieveContract.quorumVotes()).equal((friends.length + 1) / 2)
  })
  it("Retrieve call", async function () {
    let balance = await this.carol.getBalance()
    let sendValue = ethers.utils.parseEther("1")
    await this.retrieveContract.connect(this.bob).callFunc(this.carol.address, sendValue, "0x", { value: sendValue })
    let balance2 = await this.carol.getBalance()
    expect(balance2.sub(balance)).equal(sendValue)
  })
  it("Retrieve ChangeExecutor propose", async function () {
    const eta = Math.floor(Date.now() / 1000) + 100
    let tx = await (await this.retrieveContract.connect(this.carol).propose(this.isaac.address, this.ChangeExecutor, eta)).wait()
    let proposeId = tx.events?.filter((x) => {
      return x.event == "ProposalCreated"
    })[0].args[0]
    const propose = await this.retrieveContract.proposals(proposeId)
    expect(propose["id"]).equal(proposeId)
    expect(propose["executeType"]).equal(this.ChangeExecutor)
    expect(propose["target"]).equal(this.isaac.address)
    expect(propose["proposer"]).equal(this.carol.address)
    expect(propose["eta"]).equal(eta)
    expect(await this.retrieveContract.state(proposeId)).equal(0)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    // castVote
    await this.retrieveContract.connect(this.carol).castVote(proposeId)
    expect(await this.retrieveContract.state(proposeId)).equal(0)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    await this.retrieveContract.connect(this.dave).castVote(proposeId)
    expect(await this.retrieveContract.state(proposeId)).equal(1)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    // execute
    expect(await this.retrieveContract.pendingExecutor()).equal("0x0000000000000000000000000000000000000000")
    await this.retrieveContract.execute(proposeId)
    expect(await this.retrieveContract.pendingExecutor()).equal(this.isaac.address)
    expect(await this.retrieveContract.state(proposeId)).equal(3)

    // accept
    await this.retrieveContract.connect(this.isaac).acceptExecutor()
    expect(await this.retrieveContract.pendingExecutor()).equal("0x0000000000000000000000000000000000000000")
    expect(await this.retrieveContract.executor()).equal(this.isaac.address)
  })

  it("Retrieve AddFriend propose", async function () {
    const eta = Math.floor(Date.now() / 1000) + 100
    let tx = await (await this.retrieveContract.connect(this.carol).propose(this.isaac.address, this.AddFriend, eta)).wait()
    let proposeId = tx.events?.filter((x) => {
      return x.event == "ProposalCreated"
    })[0].args[0]
    const propose = await this.retrieveContract.proposals(proposeId)
    expect(propose["id"]).equal(proposeId)
    expect(propose["executeType"]).equal(this.AddFriend)
    expect(propose["target"]).equal(this.isaac.address)
    expect(propose["proposer"]).equal(this.carol.address)
    expect(propose["eta"]).equal(eta)
    expect(await this.retrieveContract.state(proposeId)).equal(0)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    // castVote
    await this.retrieveContract.connect(this.carol).castVote(proposeId)
    expect(await this.retrieveContract.state(proposeId)).equal(0)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    await this.retrieveContract.connect(this.dave).castVote(proposeId)
    expect(await this.retrieveContract.state(proposeId)).equal(1)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    // execute
    expect(await this.retrieveContract.getPendingFriends()).to.have.lengthOf(0)
    await this.retrieveContract.execute(proposeId)
    expect(await this.retrieveContract.getPendingFriends()).to.have.lengthOf(1)
    expect(await this.retrieveContract.getPendingFriends()).to.include(this.isaac.address)
    expect(await this.retrieveContract.state(proposeId)).equal(3)

    // accept
    await this.retrieveContract.connect(this.isaac).acceptFriend()
    expect(await this.retrieveContract.getPendingFriends()).to.have.lengthOf(0)

    expect(await this.retrieveContract.getFriends()).to.have.lengthOf(4)
    expect(await this.retrieveContract.getFriends()).to.include(this.isaac.address)
  })

  it("Retrieve RemoveFriend propose", async function () {
    const eta = Math.floor(Date.now() / 1000) + 100
    let tx = await (await this.retrieveContract.connect(this.carol).propose(this.carol.address, this.RemoveFriend, eta)).wait()
    let proposeId = tx.events?.filter((x) => {
      return x.event == "ProposalCreated"
    })[0].args[0]
    const propose = await this.retrieveContract.proposals(proposeId)
    expect(propose["id"]).equal(proposeId)
    expect(propose["executeType"]).equal(this.RemoveFriend)
    expect(propose["target"]).equal(this.carol.address)
    expect(propose["proposer"]).equal(this.carol.address)
    expect(propose["eta"]).equal(eta)
    expect(await this.retrieveContract.state(proposeId)).equal(0)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    // castVote
    await this.retrieveContract.connect(this.carol).castVote(proposeId)
    expect(await this.retrieveContract.state(proposeId)).equal(0)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    await this.retrieveContract.connect(this.dave).castVote(proposeId)
    expect(await this.retrieveContract.state(proposeId)).equal(1)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    // execute
    expect(await this.retrieveContract.getFriends()).to.have.lengthOf(3)
    await this.retrieveContract.execute(proposeId)
    expect(await this.retrieveContract.getFriends()).to.have.lengthOf(2)
    expect(await this.retrieveContract.getFriends()).to.not.include(this.carol.address)
  })

  it("Retrieve votesign propose", async function () {
    const eta = Math.floor(Date.now() / 1000) + 100
    let tx = await (await this.retrieveContract.connect(this.carol).propose(this.carol.address, this.RemoveFriend, eta)).wait()
    let proposeId = tx.events?.filter((x) => {
      return x.event == "ProposalCreated"
    })[0].args[0]
    const propose = await this.retrieveContract.proposals(proposeId)
    expect(propose["id"]).equal(proposeId)
    expect(propose["executeType"]).equal(this.RemoveFriend)
    expect(propose["target"]).equal(this.carol.address)
    expect(propose["proposer"]).equal(this.carol.address)
    expect(propose["eta"]).equal(eta)
    expect(await this.retrieveContract.state(proposeId)).equal(0)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    // castVote
    const domain = {
      name: "RetrieveV1",
      chainId: this.chainId,
      verifyingContract: this.retrieveContract.address,
    }

    const types = {
      Ballot: [{ name: "proposalId", type: "uint256" }],
    }
    const value = {
      proposalId: proposeId,
    }

    const carolSignTypedData = ethers.utils.splitSignature(await this.carol._signer._signTypedData(domain, types, value))
    const daveSignTypedData = ethers.utils.splitSignature(await this.dave._signer._signTypedData(domain, types, value))

    await this.retrieveContract.connect(this.carol).castVoteBySig(proposeId, carolSignTypedData.v, carolSignTypedData.r, carolSignTypedData.s)
    expect(await this.retrieveContract.state(proposeId)).equal(0)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    await this.retrieveContract.connect(this.dave).castVoteBySig(proposeId, daveSignTypedData.v, daveSignTypedData.r, daveSignTypedData.s)
    expect(await this.retrieveContract.state(proposeId)).equal(1)
    // console.log(await this.retrieveContract.state(proposeId), (await this.retrieveContract.proposals(proposeId))["forVotes"])

    // execute
    expect(await this.retrieveContract.getFriends()).to.have.lengthOf(3)
    await this.retrieveContract.execute(proposeId)
    expect(await this.retrieveContract.getFriends()).to.have.lengthOf(2)
    expect(await this.retrieveContract.getFriends()).to.not.include(this.carol.address)
  })
})
