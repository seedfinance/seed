const { expect } = require("chai");

describe("CronUser", () => {
  before(async function () {
    this.signers = await ethers.getSigners();
    this.admin = this.signers[0];
    this.AdminStorage = await ethers.getContractFactory("AdminStorage");
    this.adminStorage = await AdminStorage.deploy(admin.address);
    this.SwapStorage = await ethers.getContractFactory("SwapStorage");
    this.swapStorage = await SwapStorage.deploy();
    await this.swapStorage.initialize(this.adminStorage.address);
    let pathes = [
      {
        from: "initialize",
        to: "initialize",
        path: [],
        router: "initialize",
      },
    ];
    for (let i = 0; i < pathes.length; i++) {
      await this.swapStorage
        .connect(admin)
        .setPath(
          pathes[i].from,
          pathes[i].to,
          pathes[i].path,
          pathes[i].router
        );
    }
  });

  beforeEach(async function () {
    /*
        this.adminStorage = await this.AdminStorage.deploy(this.admin.address);
        this.userManagerStorage = await this.UserManagerStorage.deploy();
        this.factory = await this.Factory.deploy();
        await this.factory.initialize(this.adminStorage.address, this.userManagerStorage.address);
        */
  });

  it("Create User", async function () {
    /*
        expect(await this.factory.userManagerStorage()).equal(this.userManagerStorage.address);
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
        */
  });

  it("Factory Change Implementation", async function () {});

  it("delegate create", async function () {});
});
