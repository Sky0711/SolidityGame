//SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.4;


// Structure for the player character properties
    struct Character {
        uint64 hp;              // Character's health
        uint64 damage;          // Damage done by the player
        uint64 xp;              // Experience
        uint64 constitution;    // Equals to MaxHp of the Character;
        bool exists;            // True if Character is already created
    }

