//SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.4;


// Structure for the In-Game Boss properties
struct Boss {
    uint64 hp;      // Boss health
    uint64 damage;  // Damage output
    uint64 reward;  // Xp reward
    bool exists;    // True if the Boss is already created
}
