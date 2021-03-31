module.exports = async ({
  ethers,
  getNamedAccounts,
  deployments,
  getChainId,
  getUnnamedAccounts,
}) => {
  const {
    deploy
  } = deployments;
  const {
    deployer
  } = await getNamedAccounts();


	const storage = await deployments.get("AdminStorage")
  const chainId = await getChainId()
  console.log("deployer:", deployer, 'chainId:', chainId)

  let ERC20Token;
  if (chainId == 128 || chainId == 31337) {
    // mainnet
    ERC20Token = {
      'USDT': '0xa71edc38d189767582c38a3145b5873052c3e47a',
      'HUSD': '0x0298c2b32eae4da002a15f36fdf7615bea3da047'
    }
  } else if (chainId == 256) {
    ERC20Token = {
      'USDT': '0x04F535663110A392A6504839BEeD34E019FdB4E0',
      'HUSD': '0x8Dd66eefEF4B503EB556b1f50880Cc04416B916B'
    }
  }

  for (let k in ERC20Token) {
    const sToken  = await deploy(k + '\'sVault', {
      from: deployer,
      contract: "VaultERC2612",
      gasLimit: 4000000,
      args: [storage.address, ERC20Token[k]],
      log: true,
      deterministicDeployment: false
    })

    console.log('deployed SToken:', sToken.address, 'from:', k, ERC20Token[k])
    // const sTokenABI = await ethers.getContractAt("VaultERC2612", sToken.address)

  }
};

module.exports.dependencies = ["AdminStorage"]