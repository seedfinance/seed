const {TOKEN, MDX} = require('./config/address.js');
module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    let richAddress = '0xeE367CE9B18b1bD445909EdaC8eb0A6C33c10A51';  //这个账户有足够多的钱
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [richAddress],
    })
    let richAccount =  await ethers.getSigner(richAddress);
    let usdtERC20 = await ethers.getContractAt('ERC20', TOKEN.USDT);
    let usdtBalance = await usdtERC20.balanceOf(richAddress);
    console.log("usdtBalance: ", usdtBalance.toString());
    let mdxERC20 = await ethers.getContractAt('ERC20', TOKEN.MDX);
    let mdxBalance = await mdxERC20.balanceOf(richAddress);
    console.log("mdxBalance: ", mdxBalance.toString());
    //创建流动性
    //let useAddress = '0xC65d28C1C62AB415F4b99f48Cb856ACEF85F7138'
    const { deployer, admin } = await ethers.getNamedSigners();
    let useAddress = admin.address;
    let useMdx = '389448259003992484544041';
    let useUsdt = '1816834362892451549735077';
    await usdtERC20.connect(richAccount).approve(MDX.Router, useUsdt);
    await mdxERC20.connect(richAccount).approve(MDX.Router, useMdx);
    console.log("useMdx: ", useMdx);
    console.log("useUsdt: ", useUsdt);
    let mdxRouter = await ethers.getContractAt('IUniswapV2Router02', MDX.Router);
    await mdxRouter.connect(richAccount).addLiquidity(TOKEN.MDX, TOKEN.USDT, useMdx, useUsdt, 0, 0, useAddress, '2620038348');

    let mdxUsdtPairERC20 = await ethers.getContractAt('ERC20', MDX.Pair.MDX_USDT);
    let mdxUsdtPairBalance = await mdxUsdtPairERC20.balanceOf(useAddress);
    console.log("mdxUsdtPairBalance: ", mdxUsdtPairBalance.toString());
    let autoInvestment = await ethers.getContract('AutoInvestment');
    let autoInvestmentRouter = await ethers.getContract('AutoInvestmentRouter');
    console.log("contract info: ");
    let info = {
        MDX : TOKEN.MDX,
        USDT: TOKEN.USDT,
        POOL: autoInvestment.address,
        ROUTER: autoInvestmentRouter.address,
    }
    console.dir(info);
};

module.exports.tags = ['TestSetting'];
module.exports.dependencies = ['SwapStorage' , 'AutoInvestment', 'AutoInvestmentRouter'];
