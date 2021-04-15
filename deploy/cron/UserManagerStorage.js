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
    let deployResult = await deploy('UserManagerStorage', {
        from: deployer.address,
        log: true,
        proxy: {
            proxyContract: 'OptimizedTransparentProxy',
            viaAdminContract: 'ProxyController',
        },
    });
    let UserManagerStorageFactory = await ethers.getContractFactory("UserManagerStorage");
    let userManagerProxy = await ethers.getContract('UserManagerStorage_Proxy');
    let userManagerStorage = await UserManagerStorageFactory.attach(userManagerProxy.address);
    let tx = await userManagerStorage.connect(deployer).initialize(adminStorage.address);
    console.log("UserManagerStorage initialize: " + tx.hash);
};

module.exports.tags = ['UserManagerStorage'];
module.exports.dependencies = ['AdminStorage'];
