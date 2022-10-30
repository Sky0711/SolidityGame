//SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./DataStructures/Boss.sol";
import "./DataStructures/Character.sol";

// TODO: Implement all user stories and one of the feature request

// NOTE: Implemented all UserStories + 1.Feature request.
// The Game contract is Upgradable, so we can add future DLC's
contract Game is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    ////////////////// Data Structures ////////////////////////////

    // BossName => Boss values
    mapping(string => Boss) BossMap; // Map of the existing Bosses

    // Player's address => Character values
    mapping(address => Character) playerCharactersMap; // Map of the player Characters

    // Boss => Player => Scar
    mapping(string => mapping(address => bool)) scars; // Players can inflict scars as the proof of their assault

    // Player => Timestamp
    mapping(address => uint32) cooldowns; // Fireball cooldowns

    // Name of the Boss that Rules the contract and has to be defeated by Players
    string RulingBoss;

    // Max value for player Character damage && health stats (default 1000)
    uint MaxValue;

    // Used for added randomness
    uint64 counter;

    /////////////////// Contract Initialization ////////////////////

    // Upgradable contract has no constructor, we need to initialise the OwnableUpgradeable explicitly
    function initialize(uint _maxValue) public initializer {
        MaxValue = _maxValue;
        __Ownable_init();
    }

    // Enables contract owner to modify allowed MaxValue for player stats
    function setMaxValue(uint newValue) external onlyOwner {
        MaxValue = newValue;
    }

    // Required by the OpenZeppelin UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    ////////////////// Owner Functionalities ///////////////////

    // Enables the contract owner to create new custom Boss
    function createBoss(string calldata BossName, Boss calldata values) external onlyOwner {
        require(!BossMap[BossName].exists, "This Boss already exists !!!");
        BossMap[BossName] = values;
    }

    // Enables the contract owner to edit characteristics of the existing Boss
    function customizeBoss(string calldata BossName, Boss calldata newValues) external onlyOwner {
        require(!isRuler(BossName), "Can't edit ruling Boss, he might be in a middle of a fight!!!");
        BossMap[BossName] = newValues;
    }

    // Enables contract owner to set "Ruling" Boss that players can try to fight.
    function appointRulingBoss(string calldata BossName) external onlyOwner {
        require(BossMap[BossName].exists, "Can't appoint a Boss that doesn't exist !!!");
        require(BossMap[RulingBoss].hp == 0, "Current ruling Boss is still alive, can't be replaced !!!");

        // Appointing a new Boss
        RulingBoss = BossName;

    }

    /////////////////// Player Actions //////////////////////////////

    // Allows users to generate playable Character
    function generateCharacter() external {
        require(!playerCharactersMap[msg.sender].exists, "Your address already have a generated Character !!!");
        Character memory newCharacter;

        // Generate random values for player Character properties;
        newCharacter.hp = random();
        newCharacter.damage = random();
        newCharacter.constitution = newCharacter.hp;
        newCharacter.exists = true;

        // Mapping new player character
        playerCharactersMap[msg.sender] = newCharacter;
    }

    // Allows players to attack the Boss that rules the contract
    function attack() external {
        // Will revert if the Boss doesn't exist too
        require(BossHp() != 0," Ruling boss is dead !!!");

        // Will revert if the player doesn't exist too
        require(PlayerHp() != 0," Player health is zero, can't attack the boss");

        // Damage the Ruling Boss
        if (BossHp() < PlayerDamage())
            BossMap[RulingBoss].hp = 0;
        else
            BossMap[RulingBoss].hp -= PlayerDamage();

        // Player's attack has inflicted a scar on the Boss !!!
        scarInflicted(RulingBoss);

        // Damage the Player
        if (PlayerHp() < BossDamage()) {
            playerCharactersMap[msg.sender].hp = 0; // Player had been knocked down by the Boss
            cutXp(); // Losing experience
        }
        else
            playerCharactersMap[msg.sender].hp -= BossDamage(); // Player hp drops
    }


    // Allows Level 2 player to heal his teammate
    function heal(address teammate) external {
        // Will revert if the player doesn't exist too
        require(PlayerHp() != 0," Player health is zero, can't cast spells !!!");

        require(playerCharactersMap[teammate].exists," Nobody to heal on that address !!!");
        require(teammate != msg.sender, "Can't heal yourself !!!");

        // Only players who already earn experiences can cast the heal spell
        require(isLevel2(), "Only Level 2 players can cast the healing spell !!!");

        // Resets the player health (full healing)
        playerCharactersMap[teammate].hp = PlayerConstitution(teammate);
    }

    // Enables Level 3 players to cast a fireball (24 hours cooldown !!!)
    function castFireball() external {
        require(PlayerHp() != 0, "Player health is zero, can't cast spells !!!");
        require(isLevel3(),"Only Level 3 players can cast a Fireball !!!");
        require(cooldowns[msg.sender] < block.timestamp + 24 hours, "The fireball spell is still in the cooldown !!!");

        // Damage the Ruling Boss (Fireball does 3 times the damage !!!)
        if (BossHp() < PlayerDamage()*3)
            BossMap[RulingBoss].hp = 0;
        else
            BossMap[RulingBoss].hp -= PlayerDamage()*3;

        // Player's attack has inflicted burning a scar on the Boss !!!
        scarInflicted(RulingBoss);

        // Fireball is ranged magic attack, the Boss can't retaliate !!!
    }

    // Marking the scar inflicted on the attacked Boss (Storing the proof of the attack into the Blockchain)
    function scarInflicted(string memory attackedBoss) internal {
        scars[attackedBoss][msg.sender] = true;
    }

    // Enabling the Player to claim his reward for the slain Boss
    function claimReward(string calldata KilledBoss) external {
        require(BossMap[KilledBoss].hp == 0, "Can't claim the reward, the Boss is still alive !!!");
        require(scars[KilledBoss][msg.sender], "You haven't left a scar on this Boss !!!");

        // Collecting xp reward
        playerCharactersMap[msg.sender].xp += BossMap[KilledBoss].reward;
    }

    /////////////////// View Functions //////////////////////////////

    // Returns the current condition of the players Character (If one exists)
    function myCharacter() external view returns (Character memory player) {
        require(playerCharactersMap[msg.sender].exists, "You don't have a character !!!");
        return playerCharactersMap[msg.sender];
    }

    // Returns True if the given boss is current ruler of the contract
    function isRuler(string calldata BossName) public view returns (bool) {
        return keccak256(abi.encodePacked(BossName)) == keccak256(abi.encodePacked(RulingBoss));
    }

    // Returns True if the caller has some Xp
    function hasXp() internal view returns (bool) {
        return playerCharactersMap[msg.sender].xp != 0;
    }

    // Returns True if the caller has Level 2 Player
    function isLevel2() internal view returns (bool) {
        // Level 2 has over 2000xp
        return playerCharactersMap[msg.sender].xp > 2000;
    }

    // Returns True if the caller has Level 3 Player
    function isLevel3() internal view returns (bool) {
        // Level 3 has over 3000xp
        return playerCharactersMap[msg.sender].xp > 3000;
    }

    // Returns hp value of the current Ruling Boss
    function BossHp() public view returns (uint64 ) {
        return BossMap[RulingBoss].hp;
    }

    // Returns damage value of the current Ruling Boss
    function BossDamage() internal view returns (uint64 ) {
        return BossMap[RulingBoss].damage;
    }

    // Returns hp value of the player's Character
    function PlayerHp() internal view returns (uint64 ) {
        return playerCharactersMap[msg.sender].hp;
    }

    // Returns damage value of the player's Character
    function PlayerDamage() internal view returns (uint64 ) {
        return playerCharactersMap[msg.sender].damage;
    }

    // Reads the player's constitution
    function PlayerConstitution(address player) internal view returns (uint64 ) {
        return playerCharactersMap[player].constitution;
    }

    // Cuts the value of the users Xp
    function cutXp() internal {
        if(playerCharactersMap[msg.sender].xp < BossMap[RulingBoss].reward)
            playerCharactersMap[msg.sender].xp = 0; // Lost all Xp
        else
            playerCharactersMap[msg.sender].xp -= BossMap[RulingBoss].reward; // Losing experience equal to reward
    }

    // (Not recommended for MainNet use !!! Implement randomness using preferred Oracle instead !!!)
    function random() internal returns (uint64 randomValue) {
        randomValue = uint64(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, counter))) % MaxValue);
        unchecked { counter++; }
    }




}
