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
