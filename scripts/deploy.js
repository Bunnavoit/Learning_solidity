import { ethers } from "hardhat";

async function main() {
  const EthLocker = await ethers.getContractFactory("EthLocker");

  const ethLocker = await EthLocker.deploy();

  await ethLocker.deployed();

  console.log("EthLocker deployed to:", ethLocker.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
