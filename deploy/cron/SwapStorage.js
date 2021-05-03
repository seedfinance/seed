const {TOKEN, MDX} = require('../config/address.js');
module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const { deployer, admin } = await ethers.getNamedSigners();
    let adminStorage = await ethers.getContract('AdminStorage');
    let deployResult = await deploy('SwapStorage', {
        from: deployer.address,
        log: true,
    });
    let swapStorage = await ethers.getContract('SwapStorage')
    await swapStorage.initialize(adminStorage.address)

    swapStorage.connect(admin).setPath(
        TOKEN.MDX,
        TOKEN.USDT,
        [TOKEN.MDX, TOKEN.USDT],
        [MDX.Pair.MDX_USDT]
    );
    console.log("set swap path: MDX<->USDT");
    console.dir({
        from: TOKEN.MDX,
        to: TOKEN.USDT,
        path: [TOKEN.MDX, TOKEN.USDT],
        pair: [MDX.Pair.MDX_USDT],
    });
    swapStorage.connect(admin).setPath(
        TOKEN.MDX,
        TOKEN.HBTC,
        [TOKEN.MDX, TOKEN.HBTC],
        [MDX.Pair.MDX_HBTC]
    );
    console.log("set swap path: MDX<->HBTC");
    console.dir({
        from: TOKEN.MDX,
        to: TOKEN.HBTC,
        path: [TOKEN.MDX, TOKEN.HBTC],
        pair: [MDX.Pair.MDX_HBTC],
    });
};

module.exports.tags = ['SwapStorage'];
module.exports.dependencies = ['AdminStorage'];
