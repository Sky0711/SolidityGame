const { ethers, upgrades } = require("hardhat");

// MaxValue for Player Character stats
const MAXVALUE = 1000;

async function main() {

  // We get the contract for deploy
 const Game = await ethers.getContractFactory("Game");

 console.log("Deploying the Game...");

  // We deploy the contract
 const game = await upgrades.deployProxy(Game, [MAXVALUE], {initializer: "initialize",});
 await game.deployed();

 console.log("Game deployed to:", game.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});