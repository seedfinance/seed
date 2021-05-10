
const {network, ethers, getNamedAccounts} = require("hardhat")
var chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const {AdminStorageDeploy, SwapStorageDeploy} = require("./utils/utils.js")
const { expandTo18Decimals,expandToNormal } = require('./utils/bignumber');


const expect = chai.expect
chai.use(chaiAsPromised)
chai.should()
const tokenReward = "0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c";
const pool = "0xFB03e11D93632D97a8981158A632Dd5986F5E909";
const eth_usdt_pid = 9;
const eth_usdt = "0x78C90d3f8A64474982417cDB490E840c01E516D4";
const factory = "0xb0b670fc1F7724119963018DB0BfA86aDb22d941";

const router = "0xED7d5F38C79115ca12fe6C0041abb22F0A06C300";
const mdx = "0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c"; // mdx
const eth_token0 = "0x64ff637fb478863b7468bc97d30a5bf3a428a1fd"; // eth
const usdt_token1 = "0xa71edc38d189767582c38a3145b5873052c3e47a"; // usdt
const mdx_usdt = "0x615E6285c5944540fd8bd921c9c8c56739Fd1E13"; // mdx_usdt
const mdx_eth = "0xb55569893b397324c0d048c9709F40c23445540E"; // mdx_eth

describe("CustomAutoInvestment", () => {
    before(async function () {
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0xeE367CE9B18b1bD445909EdaC8eb0A6C33c10A51"],
        })
        // this.bob = this.signers[1]
        this.bob = await ethers.getSigner("0xeE367CE9B18b1bD445909EdaC8eb0A6C33c10A51")
        this.carol = this.signers[2]
        this.dave = this.signers[3]
        console.log("alice:", this.alice.address)
        console.log("bob:", this.bob.address)
        console.log("carol:", this.carol.address)
        console.log("dave:", this.dave.address)

        this.adminStorage = await AdminStorageDeploy(this.bob.address)
        this.swapStorage = await SwapStorageDeploy(this.adminStorage.address)
        // swap path
        await this.swapStorage.connect(this.bob).setPath(mdx,eth_token0,[mdx,usdt_token1,eth_token0],[mdx_usdt,eth_usdt])
        await this.swapStorage.connect(this.bob).setPath(mdx,usdt_token1,[mdx,usdt_token1],[mdx_usdt])
        await this.swapStorage.connect(this.bob).setPath(eth_token0,usdt_token1,[eth_token0,usdt_token1],[eth_usdt])
        await this.swapStorage.connect(this.bob).setPath(usdt_token1,eth_token0,[usdt_token1,eth_token0],[eth_usdt])
    })

    beforeEach(async function () {
        // 部署 AutoInvestment 合约
        this.CronAutoInvestment = await ethers.getContractFactory("CustomAutoInvestment")

        this.autoInvestment = await this.CronAutoInvestment.deploy();
        await this.autoInvestment.deployed()
        let tx = await this.autoInvestment.connect(this.bob).initialize(
            this.adminStorage.address,
            this.swapStorage.address,
            tokenReward,
            pool,
            eth_usdt_pid,
            eth_usdt,
            factory,
            this.dave.address,
            this.dave.address,
            expandTo18Decimals(1)
        );
        // console.log("admin",await this.autoInvestment.storeAdmin());
        // console.log('deployed AutoInvestment:', this.autoInvestment.address);
    })

    it("should set correct contant variables", async function () {
        expect(await this.autoInvestment.tokenReward()).to.equal(tokenReward);
        expect(await this.autoInvestment.pool()).to.equal(pool);
        expect(await this.autoInvestment.pair()).to.equal(eth_usdt);
        expect(await this.autoInvestment.factory()).to.equal(factory);
        expect(await this.autoInvestment.noReInvestmentRate()).to.equal(expandTo18Decimals(1));
    })
    it("should set correct token address", async function () {
        // set tokenRework
        tx = await this.autoInvestment.connect(this.bob).setTokenReward(eth_usdt)
        expect(await this.autoInvestment.tokenReward()).to.equal(eth_usdt)
        tx = await this.autoInvestment.connect(this.bob).setNewInvest(eth_usdt)
        expect(await this.autoInvestment.newInvest()).to.equal(eth_usdt)
        tx = await this.autoInvestment.connect(this.bob).setNoReInvestmentRate(expandTo18Decimals(2))
        expect(await this.autoInvestment.noReInvestmentRate()).to.equal(expandTo18Decimals(2))
    })
    
    context("swap test", function () {
        before(async function () {
            this.ETH = await ethers.getContractAt("IERC20", eth_token0)
            this.USDT = await ethers.getContractAt("IERC20", usdt_token1)
            this.ETH_USDT = await ethers.getContractAt("IERC20", eth_usdt)
            this.MDX = await ethers.getContractAt("IERC20",mdx)
        })
        beforeEach(async function () {
            await this.MDX.connect(this.bob).approve(this.autoInvestment.address,ethers.utils.parseEther("2000"))
            await this.ETH.connect(this.bob).approve(this.autoInvestment.address,ethers.utils.parseEther("2"))
            await this.USDT.connect(this.bob).approve(this.autoInvestment.address,ethers.utils.parseEther("6000"))
        })
        it("swap should be equal correct", async function () {
            const caroUSDTBeforeBalance = await this.USDT.balanceOf(this.carol.address)
            const swapAmount = ethers.utils.parseEther("2000").toBigInt();
            tx = await this.autoInvestment.connect(this.bob).swapTokensForExactTokens(
                mdx,
                usdt_token1,
                swapAmount,
                this.carol.address
            )
            const caroUSDTAfterBalance = await this.USDT.balanceOf(this.carol.address)
            expect(caroUSDTAfterBalance.sub(caroUSDTBeforeBalance)).to.equal(swapAmount)
        })

        it("swap should be equal correct amount", async function() {           
            // approve
            const carolUSDTBeforeBalance = await this.USDT.balanceOf(this.carol.address)
            const carolETHBeforeBalance = await this.ETH.balanceOf(this.bob.address)
            const swapAmount = ethers.utils.parseEther("2500").toBigInt();
            tx = await this.autoInvestment.connect(this.bob).swapTokensForExactTokens(
                eth_token0,
                usdt_token1,
                swapAmount,
                this.carol.address
            )
            await network.provider.send("evm_mine", []);
            const carolUSDTAfterBalance = await this.USDT.balanceOf(this.carol.address)
            const caroETHAfterBalance = await this.ETH.balanceOf(this.bob.address)
            expect(carolUSDTAfterBalance.sub(carolUSDTBeforeBalance)).to.equal(swapAmount);
            console.log("swap sub usdt balance", expandToNormal(carolUSDTAfterBalance.sub(carolUSDTBeforeBalance)))
            console.log("swap sub eth balance", expandToNormal(carolETHBeforeBalance.sub(caroETHAfterBalance)))
        })
        it("swap should be equal correct amount for eth", async function() {           
            // approve
            const carolUSDTBeforeBalance = await this.USDT.balanceOf(this.bob.address)
            const carolETHBeforeBalance = await this.ETH.balanceOf(this.carol.address)
            const swapAmount = ethers.utils.parseEther("1").toBigInt();
            tx = await this.autoInvestment.connect(this.bob).swapTokensForExactTokens(
                usdt_token1,
                eth_token0,
                swapAmount,
                this.carol.address
            )
            await network.provider.send("evm_mine", []);
            const caroETHAfterBalance = await this.ETH.balanceOf(this.carol.address)
            const carolUSDTAfterBalance = await this.USDT.balanceOf(this.bob.address)
            expect(caroETHAfterBalance.sub(carolETHBeforeBalance)).to.equal(swapAmount);
            console.log("from usdt to one eth",expandToNormal(carolUSDTBeforeBalance.sub(carolUSDTAfterBalance)))
        })
    })

    context("auto investment test", function () {
        before(async function () {
            this.ETH = await ethers.getContractAt("IERC20", eth_token0)
            this.USDT = await ethers.getContractAt("IERC20", usdt_token1)
            this.ETH_USDT = await ethers.getContractAt("IERC20", eth_usdt)
            this.MDX = await ethers.getContractAt("IERC20", mdx)
            this.POOL = await ethers.getContractAt("IMdexChef", pool)

        })
        beforeEach(async function () {
            await this.ETH.connect(this.bob).approve(this.autoInvestment.address,ethers.utils.parseEther("10"))
            await this.USDT.connect(this.bob).approve(this.autoInvestment.address,ethers.utils.parseEther("5000"))
            await this.MDX.connect(this.bob).approve(this.autoInvestment.address,ethers.utils.parseEther("2000"))

        })
        it("two token eth_usdt to addLiquidity", async function (){
            // addliquidity
            const carolUSDTBeforeBalance = await this.USDT.balanceOf(this.bob.address)
            const carolETHBeforeBalance = await this.ETH.balanceOf(this.bob.address)
            tx = await this.autoInvestment.connect(this.bob).addLiquidity(
                [this.ETH.address,this.USDT.address],
                [ethers.utils.parseEther("2"),  ethers.utils.parseEther("4800")]
            )
            const carolUSDTAfterBalance = await this.USDT.balanceOf(this.bob.address)
            const caroETHAfterBalance = await this.ETH.balanceOf(this.bob.address)
            console.log("eth balance",carolUSDTBeforeBalance.toBigInt(),carolUSDTAfterBalance.toBigInt())
            console.log("usdt balance",carolETHBeforeBalance.toBigInt(),caroETHAfterBalance.toBigInt())
            
            await network.provider.send("evm_mine", []);
            let [mdxReward,tokenAmount] =  await this.POOL.pending(eth_usdt_pid, this.autoInvestment.address)
            expect(mdxReward).not.null
            console.log("two token addliquidity reward",mdxReward.toBigInt())
            console.log("use eth for addliqudity",carolETHBeforeBalance.sub(caroETHAfterBalance).toBigInt())
            expect(tokenAmount).equal(0)
        })
        it("one token eth to addLiquidity", async function (){
            const mdxBalance = await this.MDX.balanceOf(this.bob.address)
            console.log("test one token mdx",mdxBalance.toBigInt())
            // addliquidity
            tx = await this.autoInvestment.connect(this.bob).addLiquidity(
                [this.ETH.address],
                [ethers.utils.parseEther("2")]
            )
            await network.provider.send("evm_mine", []);
            let [mdxReward,tokenAmount] =  await this.POOL.pending(eth_usdt_pid, this.autoInvestment.address)
            expect(mdxReward).not.null
            expect(tokenAmount).equal(0)
        })
    })
    context("do hard work", function () {
        before(async function () {
            this.ETH = await ethers.getContractAt("IERC20", eth_token0)
            this.USDT = await ethers.getContractAt("IERC20", usdt_token1)
            this.ETH_USDT = await ethers.getContractAt("IERC20", eth_usdt)
            this.MDX = await ethers.getContractAt("IERC20", mdx)
            this.POOL = await ethers.getContractAt("IMdexChef", pool)
        })
        beforeEach(async function () {
            await this.ETH.connect(this.bob).approve(this.autoInvestment.address,ethers.utils.parseEther("2"))
            await this.USDT.connect(this.bob).approve(this.autoInvestment.address,ethers.utils.parseEther("5000"))
            // addliqudity
            tx = await this.autoInvestment.connect(this.bob).addLiquidity(
                [this.ETH.address,this.USDT.address],
                [ethers.utils.parseEther("2"),  ethers.utils.parseEther("4800")]
            )
            await network.provider.send("evm_mine", []);
        })
        it("test auto overlap", async function() {
            let [mdxReward,tokenAmount] =  await this.POOL.pending(eth_usdt_pid, this.autoInvestment.address)
            const balance = await this.MDX.balanceOf(this.autoInvestment.address)
            console.log("overlap mdx",mdxReward.toBigInt(),balance.toBigInt())
            expect(mdxReward).to.be.above(0)
        })
        it("test do hard work", async function() {
            const oldBalance = await this.MDX.balanceOf(this.autoInvestment.address)
            tx = await this.autoInvestment.connect(this.bob).doHardWork()
            const newBalance = await this.MDX.balanceOf(this.autoInvestment.address)
            console.log("do hard work",newBalance.toBigInt(),oldBalance.toBigInt())
            expect(newBalance).to.be.above(oldBalance)
        })
        it("test remove liqudity", async function() {
            let [liquidityBalance, ,]  = await this.POOL.userInfo(
                eth_usdt_pid,
                this.autoInvestment.address
            )
            const ethBalance = await this.ETH.balanceOf(this.dave.address)            
            await this.autoInvestment.connect(this.bob).removeLiquity(this.dave.address,liquidityBalance.add(1000))

            let [liquidityOldBalance, ,]  = await this.POOL.userInfo(
                eth_usdt_pid,
                this.autoInvestment.address
            )

            const ethNewBalance = await this.ETH.balanceOf(this.dave.address)
            console.log("liqudity remove for liquidity",liquidityBalance.toBigInt(),liquidityOldBalance.toBigInt())
            console.log("liqudity remove eth",ethBalance.toBigInt(),ethNewBalance.toBigInt())
            expect(liquidityBalance).to.above(liquidityOldBalance)
            expect(ethNewBalance).to.be.above(ethBalance)

        })
        it("claim to receiver", async function () {
            const receiverOldBalance = await this.MDX.balanceOf(this.dave.address)
            tx = await this.autoInvestment.connect(this.bob).claimTo()
            const receiverNewBalance = await this.MDX.balanceOf(this.dave.address)
            console.log("claim to receiver",receiverNewBalance.toBigInt(),receiverOldBalance.toBigInt())
            expect(receiverNewBalance).to.be.above(receiverOldBalance)
        })
    })
})
