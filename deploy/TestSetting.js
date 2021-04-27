module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const { receiver } = await getNamedAccounts();
    const { MDX, Factory, HBTC, USDT } = await getNamedAccounts();
    const { admin } = await ethers.getNamedSigners();
    let factory = await ethers.getContractAt("IMdexFactory", Factory)
    let swapStorage = await ethers.getContract('SwapStorage')
    let adminStorage = await ethers.getContract('AdminStorage');
    let autoInvestment = await ethers.getContract('AutoInvestment');
    let autoInvestmentRouter = await ethers.getContract('AutoInvestmentRouter');
    const MDX_USDT = await factory.getPair(MDX, USDT)
    const MDX_HBTC = await factory.getPair(MDX, USDT)

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

    let info = {
        'adminStorage': {
            'address': adminStorage.address,
            'admin': await adminStorage.admin()
        },
        'swapStorage': {
            'address': swapStorage.address,
            'admin': await adminStorage.admin()
        },
        'autoInvestment': {
            'address': autoInvestment.address,
            'pair': await autoInvestment.lpToken(),
            'masterChef': await autoInvestment.chef()
        },
        'autoInvestmentRouter': {
            'address': autoInvestmentRouter.address
        }
    }
    console.log(info)

};

module.exports.tags = ['TestSetting'];
module.exports.dependencies = ['SwapStorage' , 'AutoInvestment', 'AutoInvestmentRouter'];
