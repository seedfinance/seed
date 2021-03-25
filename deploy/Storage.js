module.exports = async ({
	ethers,
	getNamedAccounts,
	deployments,
	getChainId,
	getUnnamedAccounts,
  }) => {
	const {deploy} = deployments;
	const {deployer} = await getNamedAccounts();

	// console.log("deployer:", deployer)
	const { address } = await deploy('Storage', {
	  from: deployer,
	  contract: 'Storage',
	  gasLimit: 4000000,
	  args: [],
		log: true,
		deterministicDeployment: false
	});

	console.log('deployed Storage:', address)
};

module.exports.tags = ["Storage"]