const { expect } = require("chai");
const {TOKEN, MDX} = require('../deploy/config/address.js');

describe("AutoInvestmentRouter", () => {
  before(async function () {
    const { deployer, admin, caller } = await ethers.getNamedSigners();
    this.deployer = deployer;
    this.admin = admin;
    this.caller = caller;
    this.AdminStorage = await ethers.getContractFactory("AdminStorage");
    this.adminStorage = await this.AdminStorage.deploy(this.admin.address);

    this.SwapStorage = await ethers.getContractFactory('SwapStorage');
    this.swapStorage = await this.SwapStorage.deploy();
    await this.swapStorage.initialize(this.adminStorage.address)
    await this.swapStorage.connect(admin).setPath(
        TOKEN.MDX,
        TOKEN.USDT,
        [TOKEN.MDX, TOKEN.USDT],
        [MDX.Pair.MDX_USDT]
    );
    await this.swapStorage.connect(admin).setPath(
        TOKEN.MDX,
        TOKEN.HBTC,
        [TOKEN.MDX, TOKEN.HBTC],
        [MDX.Pair.MDX_HBTC]
    );
    let richAddress = '0xeE367CE9B18b1bD445909EdaC8eb0A6C33c10A51';  //这个账户有足够多的钱
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [richAddress],
    })
    this.mdxERC20 = await ethers.getContractAt('ERC20', TOKEN.MDX);
    this.usdtERC20 = await ethers.getContractAt('ERC20', TOKEN.USDT);
    this.mdxUsdtLpERC20 = await ethers.getContractAt('ERC20', MDX.Pair.MDX_USDT);
    let richAccount =  await ethers.getSigner(richAddress);
    let usdtERC20 = await ethers.getContractAt('ERC20', TOKEN.USDT);
    let usdtBalance = await usdtERC20.balanceOf(richAddress);
    //console.log("usdtBalance: ", usdtBalance.toString());
    let mdxERC20 = await ethers.getContractAt('ERC20', TOKEN.MDX);
    let mdxBalance = await mdxERC20.balanceOf(richAddress);
    //console.log("mdxBalance: ", mdxBalance.toString());
    //创建流动性
    //let useAddress = '0xC65d28C1C62AB415F4b99f48Cb856ACEF85F7138'
    //let useMdx = mdxBalance;
    //let useUsdt = usdtBalance;
    let useMdx = '389448259003992484544041';
    let useUsdt = '1816834362892451549735077';
    await usdtERC20.connect(richAccount).approve(MDX.Router, useUsdt);
    await mdxERC20.connect(richAccount).approve(MDX.Router, useMdx);
    //console.log("useMdx: ", useMdx);
    //console.log("useUsdt: ", useUsdt);
    let mdxRouter = await ethers.getContractAt('IUniswapV2Router02', MDX.Router);
    await mdxRouter.connect(richAccount).addLiquidity(TOKEN.MDX, TOKEN.USDT, useMdx, useUsdt, 0, 0, this.caller.address, '2620038348');

  });

  beforeEach(async function () {
    this.AutoInvestmentRouter = await ethers.getContractFactory('AutoInvestmentRouter');
    this.autoInvestmentRouter = await this.AutoInvestmentRouter.deploy(this.adminStorage.address, this.swapStorage.address);
    
    this.AutoInvestment = await ethers.getContractFactory('AutoInvestment');
    this.autoInvestment = await this.AutoInvestment.deploy(
            this.adminStorage.address,
            this.swapStorage.address,
            MDX.MasterChef,
            TOKEN.MDX,
            MDX.Pair.MDX_USDT,
            MDX.Pid.MDX_USDT,
    );
  });

  it("PoolInfo", async function() {
    expect(await this.autoInvestmentRouter.getPoolInfoNum()).to.equal(0);
    //add
    await this.autoInvestmentRouter.addPool(this.admin.address, this.admin.address, this.admin.address, this.admin.address, "8");
    expect(await this.autoInvestmentRouter.getPoolInfoNum()).to.equal(1);
    let res = await this.autoInvestmentRouter.getAllPoolInfo();
    expect(res.length).to.equal(1);
    expect(res[0].pool).to.equal(this.admin.address);
    expect(res[0].masterChef).to.equal(this.admin.address);
    expect(res[0].rewardToken).to.equal(this.admin.address);
    expect(res[0].lpToken).to.equal(this.admin.address);
    expect(res[0].pid).to.equal(8);
    //set
    await this.autoInvestmentRouter.setPool("0", this.deployer.address, this.deployer.address, this.deployer.address, this.deployer.address, "9");
    res = await this.autoInvestmentRouter.getAllPoolInfo();
    expect(res.length).to.equal(1);
    expect(res[0].pool).to.equal(this.deployer.address);
    expect(res[0].masterChef).to.equal(this.deployer.address);
    expect(res[0].rewardToken).to.equal(this.deployer.address);
    expect(res[0].lpToken).to.equal(this.deployer.address);
    expect(res[0].pid).to.equal(9);
    //del
    await this.autoInvestmentRouter.delPool("0");
    expect(await this.autoInvestmentRouter.getPoolInfoNum()).to.equal(0);
  });

  it("GetPrice", async function() {
    let ERC20 = await ethers.getContractFactory("MockERC20"); 
    //建立多个测试token
    let mdxERC20 = await ERC20.deploy("MDX", "MDX", 18, this.caller.address);
    let hbtcERC20 = await ERC20.deploy("HBTC", "HBTC", 18, this.caller.address);
    let hethERC20 = await ERC20.deploy("HETH", "HETH", 18, this.caller.address);
    let usdtERC20 = await ERC20.deploy("USDT", "USDT", 18, this.caller.address);
    expect(await mdxERC20.balanceOf(this.caller.address)).to.equal("1000000000000000000000000000000");
    expect(await hbtcERC20.balanceOf(this.caller.address)).to.equal("1000000000000000000000000000000");
    expect(await hethERC20.balanceOf(this.caller.address)).to.equal("1000000000000000000000000000000");
    expect(await usdtERC20.balanceOf(this.caller.address)).to.equal("1000000000000000000000000000000");
    let mdxFactory = await ethers.getContractAt("IMdexFactory", MDX.Factory);
    let mdxRouter = await ethers.getContractAt("IUniswapV2Router02", MDX.Router);

    await mdxFactory.connect(this.caller).createPair(hethERC20.address, usdtERC20.address);
    let hethUsdtPair = await mdxFactory.getPair(hethERC20.address, usdtERC20.address);
    await usdtERC20.connect(this.caller).approve(mdxRouter.address, '100000000000000000000');
    await hethERC20.connect(this.caller).approve(mdxRouter.address, '1000000000000000000');
    await mdxRouter.connect(this.caller).addLiquidity(usdtERC20.address, hethERC20.address, '100000000000000000000', '1000000000000000000', '100000000000000000000', '1000000000000000000', this.caller.address, '2620038348');
    await this.swapStorage.connect(this.admin).setPath(hethERC20.address, usdtERC20.address, [hethERC20.address, usdtERC20.address], [hethUsdtPair]);
    expect(await this.autoInvestmentRouter.getPrice(hethERC20.address, usdtERC20.address)).to.equal("100000000000000000000");
    
    await mdxFactory.connect(this.caller).createPair(hethERC20.address, hbtcERC20.address);
    let hbtcHethPair = await mdxFactory.getPair(hethERC20.address, hbtcERC20.address);
    await hethERC20.connect(this.caller).approve(mdxRouter.address, '100000000000000000000');
    await hbtcERC20.connect(this.caller).approve(mdxRouter.address, '1000000000000000000');
    await mdxRouter.connect(this.caller).addLiquidity(hbtcERC20.address, hethERC20.address, '1000000000000000000', '100000000000000000000', '1000000000000000000', '100000000000000000000', this.caller.address, '2620038348');
    await this.swapStorage.connect(this.admin).setPath(hbtcERC20.address, usdtERC20.address, [hbtcERC20.address, hethERC20.address, usdtERC20.address], [hbtcHethPair, hethUsdtPair]);
    expect(await this.autoInvestmentRouter.getPrice(hbtcERC20.address, usdtERC20.address)).to.equal("10000000000000000000000");

    await mdxFactory.connect(this.caller).createPair(mdxERC20.address, hbtcERC20.address);
    let mdxHbtcPair = await mdxFactory.getPair(mdxERC20.address, hbtcERC20.address);
    await hbtcERC20.connect(this.caller).approve(mdxRouter.address, '100000000000000');
    await mdxERC20.connect(this.caller).approve(mdxRouter.address, '1000000000000000000');
    await mdxRouter.connect(this.caller).addLiquidity(mdxERC20.address, hbtcERC20.address, '1000000000000000000', '100000000000000', '1000000000000000000', '100000000000000', this.caller.address, '2620038348');
    await this.swapStorage.connect(this.admin).setPath(mdxERC20.address, usdtERC20.address, [mdxERC20.address, hbtcERC20.address, hethERC20.address, usdtERC20.address], [mdxHbtcPair, hbtcHethPair, hethUsdtPair]);
    expect(await this.autoInvestmentRouter.getPrice(mdxERC20.address, usdtERC20.address)).to.equal("1000000000000000000");

    let res = await this.autoInvestmentRouter.getPrices([hethERC20.address, hbtcERC20.address, mdxERC20.address], usdtERC20.address);
    expect(res.length).to.equal(3);
    expect(res[0]).to.equal('100000000000000000000');
    expect(res[1]).to.equal('10000000000000000000000');
    expect(res[2]).to.equal('1000000000000000000');


  });

  it("Deposit", async function () {
    expect(await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).to.be.above(0)
    let balanceBefore = await this.mdxUsdtLpERC20.balanceOf(this.caller.address);
    //console.log("balanceBefor: ", balanceBefore.toString());
    this.mdxUsdtLpERC20.connect(this.caller).approve(this.autoInvestmentRouter.address, '0xffffffffffffffff'); 
    //let res = await this.mdxUsdtLpERC20.allowance(this.caller.address, this.autoInvestmentRouter.address);
    //console.dir(res);
    expect(await this.mdxUsdtLpERC20.allowance(this.caller.address, this.autoInvestmentRouter.address)).to.be.above(0);
    await this.autoInvestmentRouter.connect(this.caller).deposit(this.autoInvestment.address, '1000000000000000000', this.caller.address);
    let balanceAfter = await this.mdxUsdtLpERC20.balanceOf(this.caller.address);
    //console.log("balaceAfter: ", balanceAfter.toString());
    expect(await this.autoInvestment.balanceOf(this.caller.address)).equal('1000000000000000000');
    //console.dir(res.toString());
  });

  it("Withdraw", async function () {
    expect(await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).to.be.above(0)
    let balanceBefore = await this.mdxUsdtLpERC20.balanceOf(this.caller.address);
    //console.log("balanceBefor: ", balanceBefore.toString());
    this.mdxUsdtLpERC20.connect(this.caller).approve(this.autoInvestmentRouter.address, '0xffffffffffffffff'); 
    //let res = await this.mdxUsdtLpERC20.allowance(this.caller.address, this.autoInvestmentRouter.address);
    //console.dir(res);
    expect(await this.mdxUsdtLpERC20.allowance(this.caller.address, this.autoInvestmentRouter.address)).to.be.above(0);
    await this.autoInvestmentRouter.connect(this.caller).deposit(this.autoInvestment.address, '1000000000000000000', this.caller.address);
    let balanceAfter = await this.mdxUsdtLpERC20.balanceOf(this.caller.address);
    //console.log("balaceAfter: ", balanceAfter.toString());
    expect(await this.autoInvestment.balanceOf(this.caller.address)).equal('1000000000000000000');

    expect(await this.autoInvestment.balanceOf(this.caller.address)).equal('1000000000000000000');
    //console.log(await(await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).toString());
    await this.autoInvestmentRouter.connect(this.caller).withdraw(this.autoInvestment.address, '1000000000000000000', this.caller.address);
    expect(await this.autoInvestment.balanceOf(this.caller.address)).equal('0');
    //console.log((await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).toString());
  });

  it("DoHardWork", async function () {
    await this.autoInvestmentRouter.addPool(this.autoInvestment.address, MDX.MasterChef, TOKEN.MDX, MDX.Pair.MDX_USDT, MDX.Pid.MDX_USDT);
    expect(await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).to.be.above(0)
    let balanceBefore = await this.mdxUsdtLpERC20.balanceOf(this.caller.address);
    //console.log("balanceBefor: ", balanceBefore.toString());
    this.mdxUsdtLpERC20.connect(this.caller).approve(this.autoInvestmentRouter.address, '0xffffffffffffffff'); 
    //let res = await this.mdxUsdtLpERC20.allowance(this.caller.address, this.autoInvestmentRouter.address);
    //console.dir(res);
    expect(await this.mdxUsdtLpERC20.allowance(this.caller.address, this.autoInvestmentRouter.address)).to.be.above(0);
    await this.autoInvestmentRouter.connect(this.caller).deposit(this.autoInvestment.address, '1000000000000000000', this.caller.address);
    let balanceAfter = await this.mdxUsdtLpERC20.balanceOf(this.caller.address);
    //console.log("balaceAfter: ", balanceAfter.toString());
    expect(await this.autoInvestment.balanceOf(this.caller.address)).equal('1000000000000000000');

    expect(await this.autoInvestment.getExchangeRate()).to.equal("1000000000000000000");
    let res = await this.autoInvestmentRouter.doHardWork();
    //console.dir(res);
    expect(await this.autoInvestment.getExchangeRate()).to.above("1000000000000000000");

    expect(await this.autoInvestment.balanceOf(this.caller.address)).equal('1000000000000000000');
    //console.log(await(await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).toString());
    await this.autoInvestmentRouter.connect(this.caller).withdraw(this.autoInvestment.address, '1000000000000000000', this.caller.address);
    expect(await this.autoInvestment.balanceOf(this.caller.address)).equal('0');
    //console.log((await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).toString());
  });

});
