import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { Game } from "../typechain";
import { assert } from "console";

// MaxValue for Player Character stats
const MAXVALUE = 1000;

describe("Game contract", function () {

    beforeEach(async () => {
    // We get the contract for deploy
    const Game = await ethers.getContractFactory("Game");

    // We deploy the contract
    const contract = await upgrades.deployProxy(Game, [MAXVALUE], {initializer: "initialize",});
    await contract.deployed();
    });

    it("Play a Simple Game", async function () {

        let accounts = await ethers.getSigners();

        // We get the contract for deploy
        const Game = await ethers.getContractFactory("Game");

        // We deploy the contract
        const contract = await upgrades.deployProxy(Game, [MAXVALUE], {initializer: "initialize",});
        await contract.deployed();

        // Creating a Boss
        const boss = await contract.createBoss("Diablo3", [10000, 200, 10, true]);
        const ruler = await contract.appointRulingBoss("Diablo3");
        const mainBoss = await contract.isRuler("Diablo3");
        expect(mainBoss).to.equal(true);

        const initialBossHp = await contract.BossHp()

        // Generating Player Characters
        await contract.connect(accounts[1]).generateCharacter();
        await contract.connect(accounts[2]).generateCharacter();
        await contract.connect(accounts[3]).generateCharacter();

        // Can't create second Character
        await expect(contract.connect(accounts[3]).generateCharacter()).to.be.reverted

        // Assaulting the Boss
        await contract.connect(accounts[1]).attack();
        await contract.connect(accounts[2]).attack();
        await contract.connect(accounts[3]).attack();

        // Boss hp after the first battle
        let woundedBossHp = await contract.BossHp()
        console.log("initialBossHp:", initialBossHp);
        console.log("woundedBossHp:", woundedBossHp);
        await expect(woundedBossHp).not.equal(initialBossHp);

    });


});
