import { deployments, ethers, getNamedAccounts } from "hardhat"
import { expect } from "chai"

describe("RoleList", () => {
  before(async function () {
    this.RoleList = await ethers.getContractFactory("RoleList")
    this.Storage = await ethers.getContractFactory("Storage")
    this.signers = await ethers.getSigners()
    this.alice = this.signers[0]
    this.bob = this.signers[1]
    this.carol = this.signers[2]
  })

  beforeEach(async function () {
    this.storage = await this.Storage.deploy()
    await this.storage.deployed()
    console.log("deployed storage", this.storage.address)
    this.role = await this.RoleList.deploy(this.storage.address)
    await this.role.deployed()
    console.log("deployed role", this.role.address)
  })

  it("should owner equal signers", async function () {
    expect(await this.storage.owner(), this.signers.address)
    expect(await this.role.store(), this.storage.address)
  })

  it("should contains if add alice", async function () {
    // add alice
    await this.role.add(this.alice.address)

    // contains alice status
    expect(await this.role.contains(this.alice.address)).to.be.true

    // check role list length
    expect(await this.role.length()).to.equal(1)

    // check include alice
    expect(await this.role.at(0)).to.equal(this.alice.address)
    const roleArr = await this.role.roles()

    expect(roleArr).to.have.lengthOf(1)
    expect(roleArr).to.include(this.alice.address)
  })

  it("should exist bob if remove alice", async function () {
    // add alice
    await this.role.add(this.alice.address)
    await this.role.add(this.bob.address)

    // contains alice status
    expect(await this.role.contains(this.alice.address)).to.be.true
    expect(await this.role.contains(this.bob.address)).to.be.true

    expect(await this.role.length()).to.equal(2)

    // contains alice status
    await this.role.remove(this.alice.address)

    expect(await this.role.contains(this.alice.address)).to.be.false
    expect(await this.role.contains(this.bob.address)).to.be.true

    // check role list length
    expect(await this.role.length()).to.equal(1)
    expect(await this.role.at(0)).to.equal(this.bob.address)
    const roleArr = await this.role.roles()

    expect(roleArr).to.have.lengthOf(1)
    expect(roleArr).to.not.include(this.alice.address)
    expect(roleArr).to.include(this.bob.address)
  })
})
