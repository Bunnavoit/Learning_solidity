async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EthLocker = await ethers.getContractFactory("EthLocker");
  const ethLocker = await EthLocker.deploy();

  console.log("EthLocker address:", ethLocker.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
