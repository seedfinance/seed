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
    let deployResult = await deploy('StrategyManagerStorage', {
        from: deployer.address,
        log: true,
        proxy: {
            proxyContract: 'OptimizedTransparentProxy',
            viaAdminContract: 'ProxyController',
        },
    });
    let StrategyManagerStorageFactory = await ethers.getContractFactory("StrategyManagerStorage");
    let strategyManagerProxy = await ethers.getContract('StrategyManagerStorage_Proxy');
    let strategyManagerStorage = await StrategyManagerStorageFactory.attach(strategyManagerProxy.address);
    let tx = await strategyManagerStorage.connect(deployer).initialize(adminStorage.address);
    console.log("StrategyManagerStorage initialize: " + tx.hash);
};

module.exports.tags = ['StrategyManagerStorage'];
module.exports.dependencies = ['AdminStorage'];
