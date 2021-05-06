const {TOKEN, MDX} = require('../../config/address.js');
const {AUTOINVESTMENT} = require('../../config/autoinvestment.js');
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
    for (let i = 0 ; i < AUTOINVESTMENT.length; i ++) {
        item = AUTOINVESTMENT[i];
        //console.dir(item);
        let deployResult = await deploy('AutoInvestment_' + item.name , {
            from: deployer.address,
            args:[
                adminStorage.address,
                swapStorage.address,
                item.masterChef,
                item.rewardToken,
                item.pair,
                item.pid,
            ],
            contract: 'AutoInvestment',
            log: true,
        });
    }
};

module.exports.tags = ['AutoInvestment'];
module.exports.dependencies = ['SwapStorage'];
