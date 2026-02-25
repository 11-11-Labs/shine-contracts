// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine ErrorsLib
 * @author 11:11 Labs 
 * @notice Library containing all custom error definitions for the Orchestrator contract
 *         and its interactions with database contracts. These errors provide detailed
 *         revert messages for validation and access control failures.
 * @dev This library is used by the Orchestrator to handle domain-specific errors
 *      related to artist/user management, content registration, and fund transfers.
 */

library ErrorsLib {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Setup Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /// @dev Thrown when attempting to set database addresses after they have already been initialized
    error AddressSetupAlreadyDone();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Access Control Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /// @dev Thrown when caller is not the owner of the specified user ID
    error AddressIsNotOwnerOfUserId();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Content Existence Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /// @dev Thrown when referencing an artist ID that does not exist
    error UserIdDoesNotExist(uint256 artistId);

    /// @dev Thrown when referencing a song ID that does not exist
    error SongIdDoesNotExist(uint256 songId);

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Content Registration Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /// @dev Thrown when a title parameter is empty or zero-length
    error TitleCannotBeEmpty();

    /// @dev Thrown when a special edition name is empty or zero-length
    error SpecialEditionNameCannotBeEmpty();

    /// @dev Thrown when max supply for a special edition is zero or invalid
    error MaxSupplyMustBeGreaterThanZero();

    /// @dev Thrown when attempting to create an album with songs from different principal artists
    error ListCannotContainSongsFromDifferentPrincipalArtist();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Content Update Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /// @dev Thrown when a proposed value is not greater than the current value
    error MustBeGreaterThanCurrent();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Balance & Fund Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /// @dev Thrown when an account has insufficient balance for the requested operation
    error InsufficientBalance();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Administrative Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /// @dev Thrown when the percentage fee provided exceeds the maximum allowed (10000 basis points = 100%)
    error InvalidPercentageFee();

    /// @dev Thrown when attempting to set a contract address to the zero address
    error ProposedAddressCannotBeZero();

    /// @dev Thrown when attempting to execute a timelocked operation before the timelock expires
    error TimelockNotExpired();
}
