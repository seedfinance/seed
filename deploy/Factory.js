module.exports = async ({
	ethers,
	getNamedAccounts,
	deployments,
	getChainId,
	getUnnamedAccounts,
  }) => {
	const {deploy} = deployments;
	const {deployer} = await getNamedAccounts();

	 await deploy('FactoryDelegate', {
	  from: deployer,
	  contract: 'FactoryDelegate',
	  gasLimit: 4000000,
	  args: [
      ],
		log: true,
		deterministicDeployment: false
	});

	const factoryDelegate = await ethers.getContract("FactoryDelegate")

    await deploy('FactoryDelegator', {
        from: deployer,
        contract: 'FactoryDelegator',
        gasLimit: 4000000,
        args: [],
        log: true,
        deterministicDeployment: false
    });

	const factoryDelegator = await ethers.getContract("FactoryDelegator")
    await factoryDelegator.initialize(factoryDelegate.address, "0x")

	console.log('deployed factoryDelegate:', factoryDelegate.address)
	console.log('deployed factoryDelegator:', factoryDelegator.address)
};