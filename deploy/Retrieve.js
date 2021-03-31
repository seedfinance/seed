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
	const { address } = await deploy('Retrieve', {
	  from: deployer,
	  contract: 'Retrieve',
	  gasLimit: 4000000,
	  args: [],
		log: true,
		deterministicDeployment: false
	});

	console.log('deployed Retrieve:', address)
};

module.exports.dependencies = ["AdminStorage"]