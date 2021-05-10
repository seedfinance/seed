const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

module.exports.AdminStorageDeploy = async function (admin) {
  const AdminStorage = await ethers.getContractFactory("AdminStorage");
  const adminStorage = await AdminStorage.deploy(admin);
  await adminStorage.deployed();
  return adminStorage;
};

module.exports.AdminableDeploy = async function (adminStorage) {
  const Adminable = await ethers.getContractFactory("Adminable");
  const adminable = await Adminable.deploy(adminStorage);
  await adminable.deployed();
  return adminable;
};
module.exports.AdminableInitDeploy = async function (adminStorage) {
  const AdminableInit = await ethers.getContractFactory("AdminableInit");
  const adminableInit = await AdminableInit.deploy();
  await adminableInit.deployed();
  await adminableInit.initializeAdmin(adminStorage);
  return adminableInit;
};
module.exports.LPStorageDeploy = async function (adminStorage) {
  const LPStorage = await ethers.getContractFactory("LPStorage");
  const lPStorage = await LPStorage.deploy();
  await lPStorage.deployed();
  await lPStorage.initializeLiquidity(adminStorage);
  return lPStorage;
};
module.exports.LpableInitDeploy = async function (lPStorage) {
  const LPableInit = await ethers.getContractFactory("LPableInit");
  const lPableInit = await LPableInit.deploy();
  await lPableInit.deployed();
  await lPableInit.initializeLiquidity(lPStorage);
  return lPableInit;
};
module.exports.SwapStorageDeploy = async function (adminStorage) {
  const SwapStorage = await ethers.getContractFactory("SwapStorage");
  const swapStorage = await SwapStorage.deploy();
  await swapStorage.deployed();
  await swapStorage.initialize(adminStorage);
  return swapStorage;
};

module.exports.LiquidityStorageDeploy = async function (
  adminStorage,
  swapStorage
) {
  const LiquidityStorage = await ethers.getContractFactory("LiquidityStorage");
  const liquidityStorage = await LiquidityStorage.deploy();
  await liquidityStorage.deployed();
  await liquidityStorage.initializeLiquidity(adminStorage, swapStorage);
  return liquidityStorage;
};
module.exports.LPBuilderDeploy = async function (
  adminStorage,
  liquidityStore,
  factory,
  pair
) {
  const LPBuilder = await ethers.getContractFactory("LPBuilder");
  const lpBuilder = await LPBuilder.deploy();
  await lpBuilder.deployed();
  await lpBuilder.initialize(adminStorage, liquidityStore, factory, pair);
  return lpBuilder;
};

module.exports.SwapPath = [
    //mdx->eth 
    {
        from: '0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c',
        to: '0x64ff637fb478863b7468bc97d30a5bf3a428a1fd',
        path: ['0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c', '0xa71edc38d189767582c38a3145b5873052c3e47a', '0x64ff637fb478863b7468bc97d30a5bf3a428a1fd'],
        pair: ['0x615E6285c5944540fd8bd921c9c8c56739Fd1E13', '0x78C90d3f8A64474982417cDB490E840c01E516D4'],
    },
    //mdx->usdt
    {
        from: '0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c',
        to: '0xa71edc38d189767582c38a3145b5873052c3e47a',
        path: ['0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c', '0xa71edc38d189767582c38a3145b5873052c3e47a'],
        pair: ['0x615E6285c5944540fd8bd921c9c8c56739Fd1E13'],
    },
]
