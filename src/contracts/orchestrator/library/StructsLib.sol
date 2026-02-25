// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine StructsLib
 * @author 11:11 Labs 
 * @notice Library containing all data structure definitions for the Orchestrator contract.
 *         These structs manage database addresses, operational breakers, and stablecoin
 *         upgrade proposals with time locks.
 * @dev Used internally by Orchestrator to maintain state related to database connections
 *      and administrative controls.
 */

library StructsLib {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Database Management 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    
    /**
     * @notice Stores the contract addresses of all database contracts
     * @param album Address of the AlbumDB contract
     * @param song Address of the SongDB contract
     * @param user Address of the UserDB contract
     */
    struct DataBaseList {
        address album;
        address song;
        address user;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Operational Control 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    
    /**
     * @notice Tracks operational breaker flags for contract lifecycle management
     * @dev Breaker flags prevent accidental reinitialization or reentrancy
     * @param addressSetup Flag indicating if database addresses have been initialized (0x00 = not set, 0x01 = set)
     * @param shop Flag for potential future operational control
     */
    struct Breakers {
        bytes1 addressSetup;
        bytes1 shop;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Stablecoin Management 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    
    /**
     * @notice Manages stablecoin address with time-locked upgrades
     * @dev Implements a two-step process: propose new address, then execute after timelock
     * @param current The currently active stablecoin contract address
     * @param proposed The proposed new stablecoin contract address (0x0 if no proposal)
     * @param timeToExecute Timestamp when the proposed change can be executed (1 day from proposal)
     */
    struct AddressProposal {
        address current;
        address proposed;
        uint256 timeToExecute;
    }
}