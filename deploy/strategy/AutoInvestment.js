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
    let adminStorage = await ethers.getContract('AdminStorage');
    let swapStorage = await ethers.getContract('SwapStorage');
    //部署LPBuilder合约
    let factory = await ethers.getContractAt("IMdexFactory", Factory)
    let chef = await ethers.getContractAt("IMdexChef", MDXChef)
    const HBTC_USDT = await factory.getPair(HBTC, USDT)
    const pid = await chef.LpOfPid(HBTC_USDT)
    let deployResult = await deploy('AutoInvestment', {
        from: deployer.address,
        args:[
            adminStorage.address,
            swapStorage.address,
            MDXChef,
            MDX,
            HBTC_USDT,
            pid
        ]
    });
};

module.exports.tags = ['AutoInvestment'];
module.exports.dependencies = ['SwapStorage'];
