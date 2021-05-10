const {TOKEN, MDX} = require('../config/address.js');
const {AUTOINVESTMENT} = require('../config/custominvestment.js');
module.exports = async ({
	ethers,
	network,
	getNamedAccounts,
	deployments,
	getChainId,
	getUnnamedAccounts,
  }) => {
	const {deploy} = deployments;
    const { receiver } = await getNamedAccounts();
	const { deployer, admin } = await ethers.getNamedSigners();
	const chainId = await getChainId();

	let adminStorage = await ethers.getContract('AdminStorage');
    let swapStorage = await ethers.getContract('SwapStorage');

	// 部署 CustomAutoInvestment 合约
	for (let i = 0 ; i < AUTOINVESTMENT.length; i ++) {
        item = AUTOINVESTMENT[i];
        let deployResult = await deploy('AutoInvestment_' + item.name , {
            from: deployer.address,
            args:[],
            contract: 'CustomAutoInvestment',
            log: true,
        });	
		console.log('deployed AutoInvestment:', deployResult.address,item.name);
	}
	
	

};

module.exports.tags = ['CustomAutoInvestment'];
module.exports.dependencies = ['AdminStorage','SwapStorage'];