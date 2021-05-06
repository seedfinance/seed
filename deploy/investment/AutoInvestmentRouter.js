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
    let swapStorage = await ethers.getContract('SwapStorage');

    let deployResult = await deploy('AutoInvestmentRouter', {
        from: deployer.address,
        args:[
            adminStorage.address,
            swapStorage.address,
        ],
        log: true
    });
    //console.log('AutoInvestmentRouter', deployResult.address)

};

module.exports.tags = ['AutoInvestmentRouter'];
module.exports.dependencies = ['SwapStorage'];
