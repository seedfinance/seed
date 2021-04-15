module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const { deployer, admin } = await ethers.getNamedSigners();
    //部署AdminStorage合约
    let deployResult = await deploy('AdminStorage', {
        from: deployer.address,
        args: [admin.address],
        log: true,
    });
    let adminStorage = await ethers.getContract('AdminStorage');
    //部署ProxyController合约
    deployResult = await deploy('ProxyController', {
        from: deployer.address,
        args: [adminStorage.address],
        log: true,
    });
};

module.exports.tags = ['AdminStorage'];
module.exports.dependencies = [];
