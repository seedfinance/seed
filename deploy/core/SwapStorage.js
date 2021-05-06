const {PATH} = require('../../config/path.js');
const util = require('util');

function differentPath(pathListA, pathListB) {
    if (pathListA.length != pathListB.length) {
        return true;
    }
    for (let i = 0; i < pathListA.length; i ++) {
        if (pathListA[i].toLowerCase() != pathListB[i].toLowerCase()) {
            return true;
        }
    }
    return false;
}

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
    let swapStorageAdmin = await swapStorage.getAdminStorage();
    if (swapStorageAdmin == '0x0000000000000000000000000000000000000000') {
        await swapStorage.initialize(adminStorage.address)
        console.log("SwapStorage initialize finish: ", adminStorage.address);
    }
    swapStorageAdmin = await swapStorage.getAdminStorage();
    for (let i = 0; i < PATH.length; i ++) {
        let path = PATH[i];
        //获取现有数据
        let currentPath = await swapStorage.pathFor(path.from, path.to);
        //console.dir(currentPath);
        if (currentPath.pair.length == 0 || currentPath.path.length == 0) { //记录不存在则创建
            await swapStorage.connect(admin).setPath(path.from, path.to, path.path, path.pair);
            console.dir(util.format("add new Path: [%s->%s]", path.from, path.to));
            console.dir(path);
        } else if (differentPath(currentPath.pair, path.pair) || differentPath(currentPath.path, path.path)) {
            await swapStorage.connect(admin).setPath(path.from, path.to, path.path, path.pair);
            console.dir(util.format("update current Path: [%s->%s]", path.from, path.to));
            console.dir(path);
        }
        //console.dir(path);
        /*
    function setPath(
        address _from,
        address _to,
        address[] calldata _path,
        address[] calldata _pair
    ) external onlyAdmin {
        */
    }

    /*

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
    */
};

module.exports.tags = ['SwapStorage'];
module.exports.dependencies = ['AdminStorage'];
