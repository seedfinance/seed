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
    //部署LPBuilder合约
    let deployResult = await deploy('AutoInvestmentRouter', {
        from: deployer.address,
        args:[
        ]
    });
    console.log('AutoInvestmentRouter', deployResult.address)

};

module.exports.tags = ['AutoInvestmentRouter'];
