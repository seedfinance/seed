const network = require('../networks/heco.json');

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

	console.log("deployer:",deployer.address);
	console.log("chainId:",chainId);

	const tokenReward = "0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c";
	const pool = "0x7373c42502874C88954bDd6D50b53061F018422e";
	const pid = 1;
	const pair = "0x78C90d3f8A64474982417cDB490E840c01E516D4";
	/*
		token0 = "0x64FF637fB478863B7468bc97D30a5bF3A428a1fD" eth
		token1 = "0xa71EdC38d189767582C38A3145b5873052c3e47a" husd
	*/
	console.log("receiver",receiver);
	console.log("swap",swap);
	console.log("tokenReward",tokenReward);
	console.log("pool",pool);
	console.log("pid",pid);
	let adminStorage = await ethers.getContract('AdminStorage');
	let lpStorage = await ethers.getContract('LPStorage');
	//部署AdminStorage合约
    let deployAddress = await deploy('AutoInvestment', {
        from: deployer.address,
        log: true
    });
	let autoInvestment = await ethers.getContract("CronAutoInvestment")
	let tx = await autoInvestment.connect(deployer).initialize(
		adminStorage.address,
		lpStorage.address,
		tokenReward,
		pool,
		pid,
		pair,
		receiver
	);
	console.log('deployed AutoInvestment:', deployAddress);

};

module.exports.tags = ['CronAutoInvestment'];
module.exports.dependencies = ['AdminStorage','LPStorage'];