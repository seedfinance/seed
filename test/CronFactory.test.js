const { expect } = require("chai");

describe("CronFactory", () => {
  before(async function () {
    this.AdminStorage = await ethers.getContractFactory("AdminStorage");
    this.Factory = await ethers.getContractFactory("Factory");
    this.UserManagerStorage = await ethers.getContractFactory(
      "UserManagerStorage"
    );
    this.signers = await ethers.getSigners();
    console.log(this.signers);
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
    let num = await this.factory.getStrategyNum();
    expect(await this.factory.getStrategyNum()).to.equal(0);
    let strategy = this.admin.address;
    await this.factory.addStrategy(strategy);
    console.dir(this.factory.getStrategyNum);
    console.dir(await this.factory.getStrategy);
    expect(await this.factory.getStrategyNum()).equal(1);
    expect(await this.factory.getStrategyByAddress(strategy)).equal(1);
    expect(await this.factory.getStrategyById("1")).equal(strategy);
    expect(await this.factory.strategyExist(1)).equal(true);
    await this.factory.delStrategy(1);
    expect(await this.factory.strategyExist(1)).equal(false);
  });

  it("Create User", async function () {});

  it("Factory Change Implementation", async function () {});

  it("delegate create", async function () {});
});
