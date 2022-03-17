const rapid = artifacts.require("RapidToken");
const reward = artifacts.require("RewardToken");
const farm = artifacts.require("StakingFarm");

module.exports = async function (deployer) {
   
  await deployer.deploy(reward);
  await deployer.deploy(rapid);

  const re = await reward.deployed()
  const ra = await rapid.deployed()

 await deployer.deploy(farm, ra.address, re.address);
};
