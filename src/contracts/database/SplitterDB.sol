// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine SplitterDB
 * @author 11:11 Labs 
 * @notice This contract serves as a database for storing and managing revenue split configurations,
 *         allowing songs and albums to distribute earnings among multiple artists or users
 *         based on configurable basis points for the Shine music platform.
 * @dev Inherits from Ownable for access control.
 *      Only the Orchestrator contract (owner) can modify state.
 *      Uses basis points (1 bp = 0.01%) for precise percentage calculations.
 */

import {IdUtils} from "@shine/library/IdUtils.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract SplitterDB is Ownable {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @dev Thrown when attempting to register or update with an empty split metadata array
    error DataIsEmpty();
    /// @dev Thrown when a split entry has zero basis points assigned
    error SplitBasisPointsCannotBeZero();
    /// @dev Thrown when cumulative basis points exceed 10000 (100%)
    error TotalBasisPointsExceed();
    /// @dev Thrown when total basis points do not equal exactly 10000 (100%)
    error MustSumToMaxBasisPoints();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Type Declarations 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Stores split configuration for a single recipient
     * @dev Each entry represents one recipient's share of revenue
     * @param isArtistId True if the recipient is an artist, false if it's a user
     * @param id The unique identifier of the recipient (artist ID or user ID)
     * @param splitBasisPoints The recipient's share in basis points (1 bp = 0.01%)
     */
    struct Metadata {
        bool isArtistId;
        uint256 id;
        uint256 splitBasisPoints;
    }

    /**
     * @notice Stores calculated split amounts for distribution
     * @dev Returned by calculateSplit to show actual amounts each recipient receives
     * @param isArtistId True if the recipient is an artist, false if it's a user
     * @param id The unique identifier of the recipient (0 indicates principal artist)
     * @param amountToReceive The calculated amount in wei or token units for this recipient
     */
    struct ReturnCalculation {
        bool isArtistId;
        uint256 id;
        uint256 amountToReceive;
    }

    /**
     * @notice Enum representing the type of entity the split is associated with
     * @dev Used as the first key in the splits mapping
     */
    enum IdType {
        User,
        Song
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 State Variables 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Maximum basis points representing 100%
     * @dev 10000 basis points = 100%, 1 basis point = 0.01%
     */
    uint256 private constant MAX_BASIC_POINTS = 10000;

    /**
     * @notice Stores split configurations for songs and users
     * @dev Mapping: IdType => entityId => array of split metadata
     *      Each entity can have multiple recipients with defined shares
     */
    mapping(IdType => mapping(uint256 id => Metadata[] splitMetadata))
        public splits;

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Events 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Emitted when a new split configuration is registered
     * @param idType The type of entity (User or Song)
     * @param id The unique identifier of the entity
     */
    event Registered(IdType indexed idType, uint256 indexed id);

    /**
     * @notice Emitted when an existing split configuration is updated
     * @param idType The type of entity (User or Song)
     * @param id The unique identifier of the entity
     */
    event Changed(IdType indexed idType, uint256 indexed id);

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Constructor 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Initializes the SplitterDB contract
     * @dev Sets the Orchestrator contract as the owner for access control
     * @param _orchestratorAddress Address of the Orchestrator contract that will manage this database
     */
    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 External Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Registers a new split configuration for a song or album
     * @dev Only callable by the Orchestrator (owner). Validates that:
     *      - Split metadata array is not empty
     *      - No entry has zero basis points
     *      - Total basis points equals exactly MAX_BASIC_POINTS (10000)
     * @param isAlbumId True if registering for an album/song, false for a user
     * @param id The unique identifier of the entity to configure splits for
     * @param splitMetadata Array of Metadata structs defining each recipient's share
     */
    function register(
        bool isAlbumId,
        uint256 id,
        Metadata[] memory splitMetadata
    ) external onlyOwner {
        if (splitMetadata.length == 0) revert DataIsEmpty();
        uint256 totalBasisPoints;
        for (uint256 i; i < splitMetadata.length; ) {
            if (splitMetadata[i].splitBasisPoints == 0)
                revert SplitBasisPointsCannotBeZero();
            totalBasisPoints += splitMetadata[i].splitBasisPoints;
            if (totalBasisPoints > MAX_BASIC_POINTS)
                revert TotalBasisPointsExceed();
            unchecked {
                ++i;
            }
        }
        if (totalBasisPoints != MAX_BASIC_POINTS)
            revert MustSumToMaxBasisPoints();

        splits[isAlbumId ? IdType.Song : IdType.User][id] = splitMetadata;

        emit Registered(isAlbumId ? IdType.Song : IdType.User, id);
    }

    /**
     * @notice Updates an existing split configuration
     * @dev Only callable by the Orchestrator (owner). Validates that:
     *      - A split configuration already exists for this entity
     *      - New split metadata array is not empty
     *      - No entry has zero basis points
     *      - Total basis points equals exactly MAX_BASIC_POINTS (10000)
     * @param isAlbumId True if updating for an album/song, false for a user
     * @param id The unique identifier of the entity to update splits for
     * @param splitMetadata Array of Metadata structs defining each recipient's new share
     */
    function change(
        bool isAlbumId,
        uint256 id,
        Metadata[] memory splitMetadata
    ) external onlyOwner {
        if (splits[isAlbumId ? IdType.Song : IdType.User][id].length == 0)
            revert DataIsEmpty();

        if (splitMetadata.length == 0) revert DataIsEmpty();
        uint256 totalBasisPoints;
        for (uint256 i; i < splitMetadata.length; ) {
            if (splitMetadata[i].splitBasisPoints == 0)
                revert SplitBasisPointsCannotBeZero();
            totalBasisPoints += splitMetadata[i].splitBasisPoints;
            if (totalBasisPoints > MAX_BASIC_POINTS)
                revert TotalBasisPointsExceed();
            unchecked {
                ++i;
            }
        }
        if (totalBasisPoints != MAX_BASIC_POINTS)
            revert MustSumToMaxBasisPoints();

        splits[isAlbumId ? IdType.Song : IdType.User][id] = splitMetadata;

        emit Changed(isAlbumId ? IdType.Song : IdType.User, id);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Getter Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Retrieves the split configuration for a given entity
     * @param isAlbumId True to query album/song splits, false for user splits
     * @param id The unique identifier of the entity
     * @return Array of Metadata structs containing all split recipients and their shares
     */
    function getSplits(
        bool isAlbumId,
        uint256 id
    ) external view returns (Metadata[] memory) {
        return splits[isAlbumId ? IdType.Song : IdType.User][id];
    }

    /**
     * @notice Calculates the actual amounts each recipient should receive from a total amount
     * @dev If no splits are configured or only one entry exists, returns the full amount
     *      directed to the principal artist (id = 0). Otherwise, calculates each
     *      recipient's share based on their basis points.
     * @param isAlbumId True to calculate for album/song, false for user
     * @param id The unique identifier of the entity
     * @param amount The total amount to be distributed (in wei or token units)
     * @return Array of ReturnCalculation structs with each recipient's calculated amount
     */
    function calculateSplit(
        bool isAlbumId,
        uint256 id,
        uint256 amount
    ) external view returns (ReturnCalculation[] memory) {
        if (splits[isAlbumId ? IdType.Song : IdType.User][id].length <= 1) {
            ReturnCalculation[] memory calculations = new ReturnCalculation[](
                1
            );
            calculations[0] = ReturnCalculation({
                    isArtistId: true,
                    id: 0,
                amountToReceive: amount
            });
            return calculations;
        } else {
            Metadata[] memory splitMetadata = splits[
                isAlbumId ? IdType.Song : IdType.User
            ][id];
            ReturnCalculation[] memory calculations = new ReturnCalculation[](
                splitMetadata.length
            );
            for (uint256 i; i < splitMetadata.length; ) {
                calculations[i] = ReturnCalculation({
                    isArtistId: splitMetadata[i].isArtistId,
                    id: splitMetadata[i].id,
                    amountToReceive: (amount *
                        splitMetadata[i].splitBasisPoints) / MAX_BASIC_POINTS
                });
                unchecked {
                    ++i;
                }
            }
            return calculations;
        }
    }
}

/**********************************
🮋🮋 Made with ❤️ by 11:11 Labs 🮋🮋
⢕⢕⢕⢕⠁⢜⠕⢁⣴⣿⡇⢓⢕⢵⢐⢕⢕⠕⢁⣾⢿⣧⠑⢕⢕⠄⢑⢕⠅⢕
⢕⢕⠵⢁⠔⢁⣤⣤⣶⣶⣶⡐⣕⢽⠐⢕⠕⣡⣾⣶⣶⣶⣤⡁⢓⢕⠄⢑⢅⢑
⠍⣧⠄⣶⣾⣿⣿⣿⣿⣿⣿⣷⣔⢕⢄⢡⣾⣿⣿⣿⣿⣿⣿⣿⣦⡑⢕⢤⠱⢐
⢠⢕⠅⣾⣿⠋⢿⣿⣿⣿⠉⣿⣿⣷⣦⣶⣽⣿⣿⠈⣿⣿⣿⣿⠏⢹⣷⣷⡅⢐
⣔⢕⢥⢻⣿⡀⠈⠛⠛⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⡀⠈⠛⠛⠁⠄⣼⣿⣿⡇⢔
⢕⢕⢽⢸⢟⢟⢖⢖⢤⣶⡟⢻⣿⡿⠻⣿⣿⡟⢀⣿⣦⢤⢤⢔⢞⢿⢿⣿⠁⢕
⢕⢕⠅⣐⢕⢕⢕⢕⢕⣿⣿⡄⠛⢀⣦⠈⠛⢁⣼⣿⢗⢕⢕⢕⢕⢕⢕⡏⣘⢕
⢕⢕⠅⢓⣕⣕⣕⣕⣵⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣷⣕⢕⢕⢕⢕⡵⢀⢕⢕
⢑⢕⠃⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⢕⢕⢕
⣆⢕⠄⢱⣄⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢁⢕⢕⠕⢁
***********************************/
