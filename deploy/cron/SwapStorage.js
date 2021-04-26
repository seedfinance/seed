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
    let deployResult = await deploy('SwapStorage', {
        from: deployer.address,
    });
    let swapStorage = await ethers.getContract('SwapStorage')
    await swapStorage.initialize(adminStorage.address)
    console.log('swapStorage',swapStorage.address)
};

module.exports.tags = ['SwapStorage'];
module.exports.dependencies = ['AdminStorage'];
