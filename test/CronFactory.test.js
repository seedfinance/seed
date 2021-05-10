const { expect } = require("chai");

describe("CronFactory", () => {
  before(async function () {
    this.AdminStorage = await ethers.getContractFactory("AdminStorage");
    this.Factory = await ethers.getContractFactory("Factory");
    this.UserManagerStorage = await ethers.getContractFactory(
      "UserManagerStorage"
    );
    this.signers = await ethers.getSigners();
    this.admin = this.signers[0];
  });

  beforeEach(async function () {
    this.adminStorage = await this.AdminStorage.deploy(this.admin.address);
    this.userManagerStorage = await this.UserManagerStorage.deploy();
    this.factory = await this.Factory.deploy();
    await this.factory.initialize(
      this.adminStorage.address,
      this.userManagerStorage.address
    );
  });

  it("Create Factory", async function () {
    expect(await this.factory.userManagerStorage()).equal(
      this.userManagerStorage.address
    );
    this.factory.setUserManagerStorage(this.admin.address);
    expect(await this.factory.userManagerStorage()).equal(this.admin.address);
    expect(await this.factory.getStrategyNum()).to.equal(0);
    await this.factory.addStrategy(this.admin.address, this.admin.address);
    expect(await this.factory.getStrategyNum()).equal(1);
    expect(await this.factory.getStrategyByAddress(this.admin.address)).equal(1);
    expect(await this.factory.getStrategyById("1")).equal(this.admin.address);
    expect(await this.factory.strategyExist(1)).equal(true);
    await this.factory.delStrategy(1);
    expect(await this.factory.strategyExist(1)).equal(false);
  });

  it("Create User", async function () {
    expect(await this.factory.userExist(this.admin.address)).equal(false);
    expect(await this.factory.getUserNum()).equal(0);
    expect(await this.factory.getUser(this.admin.address)).equal('0x0000000000000000000000000000000000000000');
    this.factory.connect(this.admin).createUser();
    expect(await this.factory.userExist(this.admin.address)).equal(true);
    expect(await this.factory.getUserNum()).equal(1);
    expect(await this.factory.getUser(this.admin.address)).not.equal('0x0000000000000000000000000000000000000000');
  });

});
