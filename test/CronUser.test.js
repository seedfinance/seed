const { expect } = require("chai");
const {AdminStorageDeploy, SwapStorageDeploy, SwapPath} = require("./utils/utils.js")

describe("CronUser", () => {
  before(async function () {
    //let signer = await ethers.getSigners();
    //this.admin = signer[0];
    //this.user = signer[1];
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: ["0xeE367CE9B18b1bD445909EdaC8eb0A6C33c10A51"],
    })
    this.user = await ethers.getSigner("0xeE367CE9B18b1bD445909EdaC8eb0A6C33c10A51")
    this.admin = await ethers.getSigner("0xeE367CE9B18b1bD445909EdaC8eb0A6C33c10A51")

    this.adminStorage = await AdminStorageDeploy(this.admin.address)
    console.log("test1", this.adminStorage.address);
    this.swapStorage = await SwapStorageDeploy(this.adminStorage.address)
    for (path in SwapPath) {
        path = SwapPath[path];
        await this.swapStorage.connect(this.admin).setPath(path.from, path.to, path.path, path.pair)
    }

    this.Factory = await ethers.getContractFactory("Factory");
    this.UserManagerStorage = await ethers.getContractFactory(
      "UserManagerStorage"
    );
    this.userManagerStorage = await this.UserManagerStorage.deploy();
    this.factory = await this.Factory.deploy();
    await this.factory.initialize(
      this.adminStorage.address,
      this.userManagerStorage.address
    );

    await this.factory.connect(this.user).createUser();
    this.userAddress = await this.factory.getUser(this.user.address);
    //console.dir(userAddress);
    this.userContract = await ethers.getContractAt('User', this.userAddress);

    this.CronAutoInvestment = await ethers.getContractFactory("CustomAutoInvestment")
    this.autoInvestment = await this.CronAutoInvestment.deploy();
    this.factory.connect(this.admin).addStrategy(this.autoInvestment.address, this.admin.address);

    this.ETH = await ethers.getContractAt("IERC20", '0x64ff637fb478863b7468bc97d30a5bf3a428a1fd')
    this.USDT = await ethers.getContractAt("IERC20", '0xa71edc38d189767582c38a3145b5873052c3e47a')
    this.MDX = await ethers.getContractAt("IERC20", '0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c')
    this.POOL = await ethers.getContractAt("IMdexChef", '0xFB03e11D93632D97a8981158A632Dd5986F5E909')

  });

  beforeEach(async function () {
  });

  it("Add Strategy", async function () {
    console.log("test3", this.adminStorage.address);
    expect(await this.factory.getStrategyById('1')).equal(this.autoInvestment.address);
    expect(await this.userContract.getStrategyNum()).equal(0);
    let ABI = [
        "function initialize(address _adminStore, address _swapStore, address _tokenReward, address _mdxChef, uint256 _mdxChefPid, address _pair, address _factory, address _receiver, address _newInvest, uint256 _overlapRate)",
    ]
    let ifact = new ethers.utils.Interface(ABI);
    let data = ifact.encodeFunctionData('initialize', [
        this.adminStorage.address,
        this.swapStorage.address,
        '0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c',
        '0xFB03e11D93632D97a8981158A632Dd5986F5E909',
        9,
        '0x78C90d3f8A64474982417cDB490E840c01E516D4',
        '0xb0b670fc1F7724119963018DB0BfA86aDb22d941',
        this.user.address,
        this.user.address,
        1
    ]);
    console.log("test4", this.adminStorage.address);
    //console.log(data);
    this.userContract.createStrategy(1, data)
    console.log("test5", this.adminStorage.address);
    expect(await this.userContract.getStrategyNum()).equal(1);
    let userStrategy= await this.userContract.getStrategy(1);
    this.userStrategyContract = await ethers.getContractAt('CustomAutoInvestment', userStrategy);
    expect(await this.userStrategyContract.pid()).equal(9);
  });

  it("Add Liquidity", async function() {
    console.log("test7", this.adminStorage.address);
    console.log(await this.autoInvestment.storeAdmin());
    await this.ETH.connect(this.user).approve(this.userStrategyContract.address,ethers.utils.parseEther("2"))
    await this.USDT.connect(this.user).approve(this.userStrategyContract.address,ethers.utils.parseEther("5000"))
    tx = await this.userStrategyContract.connect(this.user).addLiquidity(
        [this.ETH.address,this.USDT.address],
        [ethers.utils.parseEther("2"),  ethers.utils.parseEther("4800")]
    )
    await network.provider.send("evm_mine", []);
    let [mdxReward,tokenAmount] =  await this.POOL.pending(9, this.userStrategyContract.address)
    const balance = await this.MDX.balanceOf(this.userStrategyContract.address)
    console.log("overlap mdx",mdxReward.toBigInt(),balance.toBigInt())
    expect(mdxReward).to.be.above(0)
  });

});
