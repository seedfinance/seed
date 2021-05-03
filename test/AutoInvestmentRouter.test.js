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
    this.swapStorage.connect(admin).setPath(
        TOKEN.MDX,
        TOKEN.USDT,
        [TOKEN.MDX, TOKEN.USDT],
        [MDX.Pair.MDX_USDT]
    );
    this.swapStorage.connect(admin).setPath(
        TOKEN.MDX,
        TOKEN.HBTC,
        [TOKEN.MDX, TOKEN.HBTC],
        [MDX.Pair.MDX_HBTC]
    );

    this.AutoInvestmentRouter = await ethers.getContractFactory('AutoInvestmentRouter');
    this.autoInvestmentRouter = await this.AutoInvestmentRouter.deploy();
    
    this.mdxERC20 = await ethers.getContractAt('ERC20', TOKEN.MDX);
    this.usdtERC20 = await ethers.getContractAt('ERC20', TOKEN.USDT);
    this.mdxUsdtLpERC20 = await ethers.getContractAt('ERC20', MDX.Pair.MDX_USDT);
    let richAddress = '0xeE367CE9B18b1bD445909EdaC8eb0A6C33c10A51';  //这个账户有足够多的钱
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [richAddress],
    })
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

  beforeEach(async function () {
    
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
    expect(await await this.autoInvestment.balanceOf(this.caller.address)).equal('1000000000000000000');
    //console.dir(res.toString());
  });

  it("Withdraw", async function () {
    expect(await await this.autoInvestment.balanceOf(this.caller.address)).equal('1000000000000000000');
    console.log(await(await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).toString());
    await this.autoInvestmentRouter.connect(this.caller).withdraw(this.autoInvestment.address, '1000000000000000000', this.caller.address);
    expect(await await this.autoInvestment.balanceOf(this.caller.address)).equal('0');
    console.log((await this.mdxUsdtLpERC20.balanceOf(this.caller.address)).toString());
  });

});
