const {AUTOINVESTMENT} = require('../../config/autoinvestment.js');
const util = require('util');

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
    let autoInvestmentRouter = await ethers.getContract('AutoInvestmentRouter');
    for (let i = 0 ; i < AUTOINVESTMENT.length; i ++) {
        item = AUTOINVESTMENT[i];
        //console.dir(item);
        let poolContract = await ethers.getContract('AutoInvestment_' + item.name);
        let id = await autoInvestmentRouter.poolInfoMap(poolContract.address);
        //console.dir(id.toString());
        if (id.toString() == '0') {
            let tx = await autoInvestmentRouter.addPool(
                poolContract.address,
                item.masterChef,
                item.rewardToken,
                item.pair,
                item.pid
            );
            console.dir(util.format("add PoolInfo: [%s]", poolContract.address));
        } else {
            let poolInfo = await autoInvestmentRouter.getPoolInfoByPool(poolContract.address);
            //console.dir(poolInfo);
            if (poolInfo.masterChef != item.masterChef || poolInfo.rewardToken != item.rewardToken || poolInfo.lpToken != item.pair || poolInfo.pid != item.pid) {
                await autoInvestmentRouter.setPool(Integer.parseInt(id.toString()) - 1 + "", item.masterChef, item.rewardToken, item.pair, item.pid)
                console.dir(util.format("set PoolInfo: [%s]", poolContract.address));
            }
        }
    }

};

module.exports.tags = ['AutoInvestmentRouter'];
module.exports.dependencies = ['AutoInvestment'];
