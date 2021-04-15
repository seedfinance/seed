module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const { receiver } = await getNamedAccounts();
    const { deployer, admin } = await ethers.getNamedSigners();
    let adminStorage = await ethers.getContract('AdminStorage');
    //部署AdminStorage合约
    let deployResult = await deploy('Factory', {
        from: deployer.address,
        log: true,
        proxy: {
            proxyContract: 'OptimizedTransparentProxy',
            viaAdminContract: 'ProxyController',
        },
    });
    let FactoryFactory = await ethers.getContractFactory("Factory");
    let factoryProxy = await ethers.getContract('Factory_Proxy');
    let factory = await FactoryFactory.attach(factoryProxy.address);
    let tx = await factory.connect(deployer).initialize(adminStorage.address);
    console.log("Factory initialize: " + tx.hash);
    let userManagerStorage = await ethers.getContract('UserManagerStorage_Proxy');
    tx = factory.connect(admin).setUserManagerStorage(userManagerStorage.address);
    console.log("Factory setUserManagerStorage: " + tx.hash);
};

module.exports.tags = ['CronFactory'];
module.exports.dependencies = ["StrategyManagerStorage", "UserManagerStorage"];
