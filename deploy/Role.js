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

	const storage = await deployments.get("Storage")
	const { address } = await deploy('RoleList', {
	  from: deployer,
	  contract: 'RoleList',
	  gasLimit: 4000000,
	  args: [storage.address],
		log: true,
		deterministicDeployment: false
	});

	console.log('deployed roleList:', address)
};

module.exports.tags = ["RoleList"]
module.exports.dependencies = ["Storage"]