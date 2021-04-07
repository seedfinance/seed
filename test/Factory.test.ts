import { deployments, ethers, getNamedAccounts } from "hardhat"
import { expect } from "chai"

describe("Factory", () => {
  before(async function () {
    this.AdminStorage = await ethers.getContractFactory("AdminStorage")
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
  })

  beforeEach(async function () {
    this.adminStorage = await this.AdminStorage.deploy()
    await this.adminStorage.deployed()
    this.factoryDelegate = await this.FactoryDelegate.deploy()
    await this.factoryDelegate.deployed()
    this.factoryDelegator = await this.FactoryDelegator.deploy(this.adminStorage.address)
    await this.factoryDelegator.deployed()
    console.log("deployed factoryDelegate", this.factoryDelegate.address)
    console.log("deployed factoryDelegator", this.factoryDelegator.address)
    this.factoryDelegator.initialize(this.factoryDelegate.address, "0x")
    this.delegate = await ethers.getContractAt("FactoryDelegate", this.factoryDelegator.address)
  })

  it("Factory initialize", async function () {
    expect(await this.factoryDelegator.admin()).to.equal(this.adminStorage.address)
    expect(await this.factoryDelegator.Implementation()).to.equal(this.factoryDelegate.address)
  })

  // it("Factory Change admin", async function () {
  //   expect(await this.factoryDelegator.admin()).to.equal(this.adminStorage.address)

  //   let adminStorage2 = await this.AdminStorage.connect(this.bob).deploy()
  //   await adminStorage2.deployed()

  //   await this.factoryDelegator.setPendingAdmin(adminStorage2.address)

  //   expect(await this.factoryDelegator.pendingAdmin()).to.equal(adminStorage2.address)
  //   expect(await this.factoryDelegator.admin()).to.equal(this.adminStorage.address)

  //   await this.factoryDelegator.connect(this.bob).acceptAdmin()

  //   expect(await this.factoryDelegator.admin()).to.equal(adminStorage2.address)
  //   expect(await this.factoryDelegator.pendingAdmin()).to.equal("0x0000000000000000000000000000000000000000")
  // })

  it("Factory Change Implementation", async function () {
    this.newFactoryDelegate = await this.FactoryDelegate.deploy()
    await this.newFactoryDelegate.deployed()
    console.log("deployed newFactoryDelegate", this.newFactoryDelegate.address)
    await this.factoryDelegator.setPendingImplementation(this.newFactoryDelegate.address)
    expect(await this.factoryDelegator.pendingImplementation()).to.equal(this.newFactoryDelegate.address)
    expect(await this.factoryDelegator.Implementation()).to.equal(this.factoryDelegate.address)

    // console.log(await this.factoryDelegator.pendingImplementation(),await this.factoryDelegator.Implementation())
    await this.newFactoryDelegate.become(this.factoryDelegator.address)
    expect(await this.factoryDelegator.pendingImplementation()).to.equal("0x0000000000000000000000000000000000000000")
    expect(await this.factoryDelegator.Implementation()).to.equal(this.newFactoryDelegate.address)
  })

  it("delegate create", async function () {
    let tx = await (await this.delegate.connect(this.bob).create([this.carol.address, this.dave.address, this.eve.address])).wait()
    let retrieve = tx.events?.filter((x) => {
      return x.event == "Created"
    })[0].args[0]
    expect(await this.delegate.register(retrieve)).to.be.true
    let accounts = await this.delegate.getAccountIndex(this.bob.address)
    expect(accounts).to.have.lengthOf(1)
    expect(accounts).to.include(retrieve)
  })
})
