const {TOKEN, MDX} = require('../config/address.js');
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
    let deployResult = await deploy('AutoInvestment', {
        from: deployer.address,
        args:[
            adminStorage.address,
            swapStorage.address,
            MDX.MasterChef,
            TOKEN.MDX,
            MDX.Pair.HBTC_USDT,
            MDX.Pid.HBTC_USDT
        ],
        log: true,
    });
};

module.exports.tags = ['AutoInvestment'];
module.exports.dependencies = ['SwapStorage'];
