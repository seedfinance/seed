module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    
    const namedAccounts = await getNamedAccounts();
    console.dir(namedAccounts);
    const { deployer } = await getNamedAccounts();
    console.dir(deployer);
};

module.exports.tags = ['CronFactory'];
module.exports.dependencies = [];
