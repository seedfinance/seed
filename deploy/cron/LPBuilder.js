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
    let strategyManagerStorage = await ethers.getContract('StrategyManagerStorage');
    //部署LPBuilder合约
    let deployResult = await deploy('LPBuilder', {
        from: deployer.address,
    });

    let StrategyManagerStorageFactory = await ethers.getContractFactory("StrategyManagerStorage");
    let strategyManagerProxy = await ethers.getContract('StrategyManagerStorage_Proxy');
    strategyManagerStorage = await StrategyManagerStorageFactory.attach(strategyManagerProxy.address);
    let tx = await strategyManagerStorage.connect(deployer).initialize(adminStorage.address);
    console.log("StrategyManagerStorage initialize: " + tx.hash);
};

module.exports.tags = ['StrategyManagerStorage'];
module.exports.dependencies = ['AdminStorage'];
