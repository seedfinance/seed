const {network, ethers, getNamedAccounts} = require("hardhat")
var chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const {AdminStorageDeploy, LPStorageDeploy, SwapStorageDeploy, LiquidityStorageDeploy, LPBuilderDeploy} = require("./utils/utils.js")

const expect = chai.expect
chai.use(chaiAsPromised)
chai.should()

describe("Auto investment", async function () {
    before(async function () {
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0xC9121e476155eBf0B794b7B351808af3787E727d"],
          })
          this.bob = await ethers.getSigner("0xC9121e476155eBf0B794b7B351808af3787E727d")
        this.chef = await ethers.getContractAt("IMdexChef", "0xFB03e11D93632D97a8981158A632Dd5986F5E909")
        this.chefToken = "0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c"
        this.chefPid = 8 //HBTC-USDT
        this.factory = "0xb0b670fc1f7724119963018db0bfa86adb22d941"
        this.router = "0xED7d5F38C79115ca12fe6C0041abb22F0A06C300"
        this.HBTC = await ethers.getContractAt("IERC20", "0x66a79d23e58475d2738179ca52cd0b41d73f0bea")
        this.USDT = await ethers.getContractAt("IERC20", "0xa71edc38d189767582c38a3145b5873052c3e47a")
        this.HBTC_USDT = await ethers.getContractAt("IERC20", "0xFBe7b74623e4be82279027a286fa3A5b5280F77c")
        this.MDX_HBTC = "0x2Fb4bE0F2785bD6009A383f3290CC97A4e3bD46B"
        this.MDX_USDT = "0x615E6285c5944540fd8bd921c9c8c56739Fd1E13"

        this.adminStorage = await AdminStorageDeploy(this.alice.address)
        this.lpStorage = await LPStorageDeploy(this.adminStorage.address)
        this.swapStorage = await SwapStorageDeploy(this.adminStorage.address)
        this.liquidityStorage = await LiquidityStorageDeploy(this.adminStorage.address, this.swapStorage.address)
        this.lPBuilder = await LPBuilderDeploy(this.adminStorage.address, this.liquidityStorage.address, this.factory, this.HBTC_USDT.address)
        this.lpStorage.setBuilder(this.HBTC_USDT.address, this.lPBuilder.address)
        this.swapStorage.setPath(this.chefToken, this.USDT.address, [this.chefToken, this.USDT.address], this.router)
        this.swapStorage.setPath(this.chefToken, this.HBTC.address, [this.chefToken, this.HBTC.address], this.router)

        this.AutoInvestment = await ethers.getContractFactory("AutoInvestment")
        this.autoInvestment = await this.AutoInvestment.deploy(
            this.adminStorage.address,
            this.lpStorage.address,
            this.chef.address,
            this.chefToken,
            this.HBTC_USDT.address,
            this.chefPid)
        await this.autoInvestment.deployed()
    })
    it("should be check property", async function (){
        expect(await this.autoInvestment.chef()).equal(this.chef.address)
        expect(await this.autoInvestment.chefToken()).equal(this.chefToken)
        expect(await this.autoInvestment.chefPid()).equal(this.chefPid)
        expect(await this.autoInvestment.lpToken()).equal(this.HBTC_USDT.address)
    })

    context("Auto investment2", async function () {
        before(async function () {
            this.router = await ethers.getContractAt("IUniswapV2Router02", this.router)

            // const BTCBalance = await this.HBTC.balanceOf(this.bob.address)
            // const USDTBalance = await this.USDT.balanceOf(this.bob.address)
            // const pairBalance = await this.HBTC_USDT.balanceOf(this.bob.address)

            await this.HBTC.connect(this.bob).approve(this.router.address, ethers.utils.parseEther("1"));
            await this.USDT.connect(this.bob).approve(this.router.address, ethers.utils.parseEther("55000"));
            const deadline = Math.round(new Date(new Date().getTime() + 3600 * 1000).getTime() / 1000)
            tx = await (await this.router.connect(this.bob).addLiquidity(this.HBTC.address, this.USDT.address, ethers.utils.parseEther("1"),  ethers.utils.parseEther("55000"), 0, 0, this.autoInvestment.address, deadline)).wait()

            // console.log(BTCBalance.sub(await this.HBTC.balanceOf(this.bob.address)))
            // console.log(USDTBalance.sub(await this.USDT.balanceOf(this.bob.address)))
            // console.log((await this.HBTC_USDT.balanceOf(this.bob.address)).sub(pairBalance))
            // const chef = await ethers.getContractAt("IMdexChef", this.chef)
            // console.log(await chef.userInfo(8, this.bob.address))
            // console.log(await chef.connect(this.bob).withdraw(8, 0))
            const lpBalance = await this.HBTC_USDT.balanceOf(this.autoInvestment.address)
            expect(await this.autoInvestment.balanceOf(this.bob.address)).equal(0)
            await this.autoInvestment.deposit(this.bob.address)
            expect(await this.HBTC_USDT.balanceOf(this.autoInvestment.address)).equal(0)
            expect(await this.autoInvestment.balanceOf(this.bob.address)).equal(lpBalance)
        })
        it("should be check pending reward", async function (){
            // console.log(await this.chef.pending(this.chefPid, this.autoInvestment.address))
            let [mdxReward,tokenAmount] =  await this.chef.pending(this.chefPid, this.autoInvestment.address)
            // console.log(mdxReward)
            // console.log(tokenAmount)
            expect(mdxReward).equal(0)
            expect(tokenAmount).equal(0)
            console.log(1)
            await network.provider.send("evm_mine", []);
            [mdxReward,tokenAmount] = await this.chef.pending(this.chefPid, this.autoInvestment.address)
            // console.log(mdxReward)
            // console.log(tokenAmount)
            expect(mdxReward).not.null
            expect(tokenAmount).equal(0)
        })
    })
})