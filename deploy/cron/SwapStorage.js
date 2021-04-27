module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const { receiver } = await getNamedAccounts();
    const { MDXChef, MDX, Factory, HBTC, USDT } = await getNamedAccounts();
    const { deployer, admin } = await ethers.getNamedSigners();
    let factory = await ethers.getContractAt("IMdexFactory", Factory)
    // const HBTC_USDT = await factory.getPair(HBTC, USDT)
    const MDX_USDT = await factory.getPair(MDX, USDT)
    const MDX_HBTC = await factory.getPair(MDX, USDT)
    let adminStorage = await ethers.getContract('AdminStorage');
    let deployResult = await deploy('SwapStorage', {
        from: deployer.address,
    });
    let swapStorage = await ethers.getContract('SwapStorage')
    await swapStorage.initialize(adminStorage.address)
    // console.log('swapStorage',swapStorage.address)

    //settings test
    swapStorage.connect(admin).setPath(
        MDX,
        USDT,
        [MDX, USDT],
        [MDX_USDT]
      );
      swapStorage.connect(admin).setPath(
        MDX,
        HBTC,
        [MDX, HBTC],
        [MDX_HBTC]
      );
};

module.exports.tags = ['SwapStorage'];
module.exports.dependencies = ['AdminStorage'];
