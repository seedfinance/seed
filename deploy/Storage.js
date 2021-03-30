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
	const { address } = await deploy('AdminStorage', {
	  from: deployer,
	  contract: 'AdminStorage',
	  gasLimit: 4000000,
	  args: [],
		log: true,
		deterministicDeployment: false
	});

	console.log('deployed AdminStorage:', address)
};

module.exports.tags = ["AdminStorage"]