const { network, ethers, getNamedAccounts } = require("hardhat");
var chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const {
  AdminStorageDeploy,
  SwapStorageDeploy,
} = require("./utils/utils.js");

const expect = chai.expect;
chai.use(chaiAsPromised);
chai.should();

describe("Auto investment", async function () {
  before(async function () {
    this.signers = await ethers.getSigners();
    this.alice = this.signers[0];
    this.eve = this.signers[4];
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xC9121e476155eBf0B794b7B351808af3787E727d"],
    });
    this.bob = await ethers.getSigner(
      "0xC9121e476155eBf0B794b7B351808af3787E727d"
    );
    this.chef = await ethers.getContractAt(
      "IMdexChef",
      "0xFB03e11D93632D97a8981158A632Dd5986F5E909"
    );
    this.chefToken = await ethers.getContractAt(
      "IERC20",
      "0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c"
    );
    this.chefPid = 8; //HBTC-USDT
    this.router = await ethers.getContractAt(
      "IUniswapV2Router02",
      "0xED7d5F38C79115ca12fe6C0041abb22F0A06C300"
    );
    this.HBTC = await ethers.getContractAt(
      "IERC20",
      "0x66a79d23e58475d2738179ca52cd0b41d73f0bea"
    );
    this.USDT = await ethers.getContractAt(
      "IERC20",
      "0xa71edc38d189767582c38a3145b5873052c3e47a"
    );
    this.HBTC_USDT = await ethers.getContractAt(
      "IERC20",
      "0xFBe7b74623e4be82279027a286fa3A5b5280F77c"
    );
    this.MDX_HBTC = await ethers.getContractAt(
      "IERC20",
      "0x2Fb4bE0F2785bD6009A383f3290CC97A4e3bD46B"
    );
    this.MDX_USDT = await ethers.getContractAt(
      "IERC20",
      "0x615E6285c5944540fd8bd921c9c8c56739Fd1E13"
    );
  });
  beforeEach(async function () {
    this.adminStorage = await AdminStorageDeploy(this.alice.address);
    this.swapStorage = await SwapStorageDeploy(this.adminStorage.address);
    this.swapStorage.setPath(
      this.chefToken.address,
      this.USDT.address,
      [this.chefToken.address, this.USDT.address],
      [this.MDX_USDT.address]
    );
    this.swapStorage.setPath(
      this.chefToken.address,
      this.HBTC.address,
      [this.chefToken.address, this.HBTC.address],
      [this.MDX_HBTC.address]
    );

    this.AutoInvestment = await ethers.getContractFactory("AutoInvestment");
    this.autoInvestment = await this.AutoInvestment.deploy(
      this.adminStorage.address,
      this.swapStorage.address,
      this.chef.address,
      this.chefToken.address,
      this.HBTC_USDT.address,
      this.chefPid
    );
    await this.autoInvestment.deployed();
  });
  it("should be check property", async function () {
    expect(await this.autoInvestment.chef()).equal(this.chef.address);
    expect(await this.autoInvestment.chefToken()).equal(this.chefToken.address);
    expect(await this.autoInvestment.chefPid()).equal(this.chefPid);
    expect(await this.autoInvestment.lpToken()).equal(this.HBTC_USDT.address);
  });
  context("Auto investment deposit", async function () {
    before(async function () {});
    beforeEach(async function () {
      await this.HBTC.connect(this.bob).approve(
        this.router.address,
        ethers.utils.parseEther("1")
      );
      await this.USDT.connect(this.bob).approve(
        this.router.address,
        ethers.utils.parseEther("55000")
      );
      const deadline = Math.round(
        new Date(new Date().getTime() + 3600 * 1000).getTime() / 1000
      );
      await this.router
        .connect(this.bob)
        .addLiquidity(
          this.HBTC.address,
          this.USDT.address,
          ethers.utils.parseEther("1"),
          ethers.utils.parseEther("55000"),
          0,
          0,
          this.autoInvestment.address,
          deadline
        );

      this.lpBalance = await this.HBTC_USDT.balanceOf(
        this.autoInvestment.address
      );
      expect(await this.autoInvestment.balanceOf(this.bob.address)).equal(0);
      await this.autoInvestment.deposit(this.bob.address);
      expect(await this.HBTC_USDT.balanceOf(this.autoInvestment.address)).equal(
        0
      );
      expect(await this.autoInvestment.balanceOf(this.bob.address)).equal(
        this.lpBalance
      );
      let [amount, ,] = await this.chef.userInfo(
        this.chefPid,
        this.autoInvestment.address
      );
      expect(amount).equal(this.lpBalance);
    });
    it("should be check pending reward", async function () {
      let [mdxReward, tokenAmount] = await this.chef.pending(
        this.chefPid,
        this.autoInvestment.address
      );
      expect(mdxReward).equal(0);
      expect(tokenAmount).equal(0);
      await network.provider.send("evm_mine", []);
      [mdxReward, tokenAmount] = await this.chef.pending(
        this.chefPid,
        this.autoInvestment.address
      );
      expect(mdxReward).not.null;
      expect(tokenAmount).equal(0);
    });
    context("Auto Investment do hard work", async function () {
      beforeEach(async function () {
        let [amount, ,] = await this.chef.userInfo(
          this.chefPid,
          this.autoInvestment.address
        );
        await this.autoInvestment.doHardWork();
        let [amount2, ,] = await this.chef.userInfo(
          this.chefPid,
          this.autoInvestment.address
        );
        expect(amount).not.above(amount2);
      });
      it("should be withdraw", async function () {
        const share = await this.autoInvestment.balanceOf(this.bob.address);
        await this.autoInvestment
          .connect(this.bob)
          .transfer(this.autoInvestment.address, share);
        expect(await this.HBTC_USDT.balanceOf(this.eve.address)).equal(0);
        await this.autoInvestment.withdraw(this.eve.address);
        expect(await this.HBTC_USDT.balanceOf(this.eve.address)).above(
          this.lpBalance
        );
        expect(await this.HBTC_USDT.balanceOf(this.eve.address)).above(0);
      });
    });
  });
});
