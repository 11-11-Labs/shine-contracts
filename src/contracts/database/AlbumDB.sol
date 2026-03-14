// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine AlbumDB
 * @author 11:11 Labs 
 * @notice This contract serves as a database for storing and managing album metadata,
 *         including purchases, refunds, special editions, and administrative controls
 *         for the Shine music platform.
 * @dev Inherits from IdUtils for unique ID generation and Ownable for access control.
 *      Only the Orchestrator contract (owner) can modify state.
 */

import {IdUtils} from "@shine/library/IdUtils.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract AlbumDB is IdUtils, Ownable {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @dev Thrown when attempting to register a song ID already used in another album
    error SongAlreadyUsedInAlbum(uint256 songId);
    /// @dev Thrown when attempting to access an album that does not exist
    error AlbumDoesNotExist();
    /// @dev Thrown when a user tries to purchase/gift an album they already own
    error UserAlreadyOwns();
    /// @dev Thrown when attempting to purchase an album that is not available for sale
    error AlbumNotPurchasable();
    /// @dev Thrown when attempting to interact with a banned album
    error AlbumIsBanned();
    /// @dev Thrown when the special edition max supply has been reached
    error AlbumMaxSupplyReached();
    /// @dev Thrown when trying to refund an album the user has not owned
    error UserNotOwnedAlbum();
    /// @dev Thrown when trying to create or update an album with zero songs
    error AlbumCannotHaveZeroSongs();
    /// @dev Thrown when trying to access the list of owners while public visibility is disabled
    error CannotSeeListOfOwners();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Type Declarations 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Stores all metadata associated with an album
     * @dev Used to track album information, pricing, purchase status, and special editions
     * @param Title The display name of the album
     * @param PrincipalArtistId The unique identifier of the main artist
     * @param MetadataURI URI pointing to off-chain metadata (e.g., IPFS)
     * @param MusicIds Array of song IDs included in this album
     * @param Price The net purchase price for this album (in wei or token units).
     *              Does not include platform fees or taxes.
     * @param TimesBought Counter tracking total number of purchases
     * @param CanBePurchased Flag indicating if the album is available for sale
     * @param IsASpecialEdition Flag indicating if this is a limited special edition
     * @param SpecialEditionName Name identifier for the special edition
     * @param MaxSupplySpecialEdition Maximum copies available for special editions
     * @param listOfOwners Dynamic array storing all user IDs that own this album.
     *                     Used for tracking and iterating over album owners.
     * @param IsBanned Flag indicating if the album has been banned from the platform
     */
    struct Metadata {
        string Title;
        uint256 PrincipalArtistId;
        string MetadataURI;
        uint256[] MusicIds;
        uint256 Price;
        uint256 TimesBought;
        bool CanBePurchased;
        bool IsASpecialEdition;
        string SpecialEditionName;
        uint256 MaxSupplySpecialEdition;
        uint256[] listOfOwners;
        bool IsBanned;
    }

    /**
     * @notice Enum representing types of metadata changes for an album
     * @dev Used in events to indicate what type of data was modified
     */
    enum ChangeType {
        MetadataUpdated,
        PurchaseabilityChanged,
        PriceChanged
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 State Variables 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     *  @notice Tracks whether the list of album owners is publicly visible
     *  @dev If false, only the owner (Orchestrator) can view the full list
     */
    bool private listVisibility;

    /**
     *  @notice Tracks whether a user owns a specific album
     *  @dev Mapping: albumId => userId => status
     *       - 0x00 = not owned
     *       - 0x01 = bought (owned)
     *       - 0x02 = gifted (owned)
     */
    mapping(uint256 Id => mapping(uint256 userId => bytes1))
        private ownByUserId;

    /**
     *  @notice Stores all album metadata indexed by album ID
     *  @dev Private mapping to prevent direct external access
     */
    mapping(uint256 Id => Metadata) private album;

    /**
     *  @notice Tracks if a song ID is already used in any album
     *  @dev Prevents duplicate song assignments across albums
     */
    mapping(uint256 songId => uint256 Id) private songUsedInAlbum;

    /**
     * @notice Tracks the index location of a user in a album's listOfOwners array
     * @dev Used for efficient removal of users from ownership list during refunds
     */
    mapping(uint256 Id => mapping(uint256 userId => uint256 locationOnIndex))
        private ownerIndex;

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Events 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Emitted when a new album is registered in the database
     * @param albumId The unique identifier assigned to the album
     */
    event Registered(uint256 indexed albumId);

    /**
     * @notice Emitted when an album is purchased by a user
     * @param albumId The unique identifier of the purchased album
     * @param userId The unique identifier of the purchasing user
     * @param timestamp The block timestamp when the purchase occurred
     */
    event Purchased(
        uint256 indexed albumId,
        uint256 indexed userId,
        uint256 indexed timestamp
    );

    /**
     * @notice Emitted when an album is gifted to a user
     * @param albumId The unique identifier of the gifted album
     * @param userId The unique identifier of the recipient user
     * @param timestamp The block timestamp when the gift occurred
     */
    event Gifted(
        uint256 indexed albumId,
        uint256 indexed userId,
        uint256 indexed timestamp
    );

    /**
     * @notice Emitted when an album purchase is refunded
     * @param albumId The unique identifier of the refunded album
     * @param userId The unique identifier of the user receiving refund
     * @param timestamp The block timestamp when the refund occurred
     */
    event Refunded(
        uint256 indexed albumId,
        uint256 indexed userId,
        uint256 indexed timestamp
    );

    /**
     * @notice Emitted when album metadata, purchasability, or price is changed
     * @param albumId The unique identifier of the modified album
     * @param timestamp The block timestamp when the change occurred
     * @param changeType The type of change that was made
     */
    event Changed(
        uint256 indexed albumId,
        uint256 indexed timestamp,
        ChangeType indexed changeType
    );

    /**
     * @notice Emitted when an album is banned from the platform
     * @param albumId The unique identifier of the banned album
     */
    event Banned(uint256 indexed albumId);

    /**
     * @notice Emitted when an album ban is lifted
     * @param albumId The unique identifier of the unbanned album
     */
    event Unbanned(uint256 indexed albumId);

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Modifiers 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Ensures the album exists before executing the function
     * @dev Reverts with AlbumDoesNotExist if the album ID is not registered
     * @param id The album ID to validate
     */
    modifier onlyIfExist(uint256 id) {
        if (!exists(id)) revert AlbumDoesNotExist();
        _;
    }

    /**
     * @notice Ensures the album is not banned before executing the function
     * @dev Reverts with AlbumIsBanned if the album has been banned
     * @param id The album ID to validate
     */
    modifier onlyIfNotBanned(uint256 id) {
        if (album[id].IsBanned) revert AlbumIsBanned();
        _;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Constructor 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Initializes the AlbumDB contract
     * @dev Sets the Orchestrator contract as the owner for access control
     * @param _orchestratorAddress Address of the Orchestrator contract that will
     *                             manage this database
     */
    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 External Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Registers a new album in the database
     * @dev Only callable by the Orchestrator (owner). Assigns a unique ID automatically.
     * @param title The display name of the album
     * @param principalArtistId The unique ID of the main artist
     * @param metadataURI URI pointing to off-chain metadata (e.g., IPFS hash)
     * @param songIDs Array of song IDs included in this album
     * @param price The net purchase price for this album.
     *              Additional fees and taxes may apply separately.
     * @param canBePurchased Whether the album is available for purchase
     * @param isASpecialEdition Whether this is a limited special edition
     * @param specialEditionName Name for the special edition (if applicable)
     * @param maxSupplySpecialEdition Maximum copies for special edition (0 if not special)
     * @return The newly assigned album ID
     */
    function register(
        string calldata title,
        uint256 principalArtistId,
        string calldata metadataURI,
        uint256[] calldata songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string calldata specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        for (uint256 i = 0; i < songIDs.length; i++) {
            if (songUsedInAlbum[songIDs[i]] != 0)
                revert SongAlreadyUsedInAlbum(songIDs[i]);

            songUsedInAlbum[songIDs[i]] = idAssigned;
        }

        album[idAssigned] = Metadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            MetadataURI: metadataURI,
            MusicIds: songIDs,
            Price: price,
            TimesBought: 0,
            CanBePurchased: canBePurchased,
            IsASpecialEdition: isASpecialEdition,
            SpecialEditionName: specialEditionName,
            MaxSupplySpecialEdition: maxSupplySpecialEdition,
            listOfOwners: new uint256[](0),
            IsBanned: false
        });

        emit Registered(idAssigned);

        return idAssigned;
    }

    /**
     * @notice Processes a standard album purchase for a user
     * @dev Only callable by owner. Marks the album as purchased by the user and
     *      increments the purchase counter. For special editions, validates that
     *      max supply has not been reached. Reverts if: user already owns album,
     *      album is not purchasable, album is banned, or special edition max supply reached.
     * @param id The album ID to purchase
     * @param userId The unique identifier of the purchasing user
     * @return Array of song IDs included in the purchased album
     */
    function purchase(
        uint256 id,
        uint256 userId
    )
        external
        onlyOwner
        onlyIfNotBanned(id)
        onlyIfExist(id)
        returns (uint256[] memory)
    {
        if (ownByUserId[id][userId] != 0x00) revert UserAlreadyOwns();

        if (!album[id].CanBePurchased) revert AlbumNotPurchasable();

        if (album[id].IsASpecialEdition) {
            if (album[id].TimesBought >= album[id].MaxSupplySpecialEdition) {
                revert AlbumMaxSupplyReached();
            }
        }

        ownByUserId[id][userId] = 0x01;
        album[id].TimesBought++;
        album[id].listOfOwners.push(userId);
        ownerIndex[id][userId] = album[id].listOfOwners.length;

        emit Purchased(id, userId, block.timestamp);

        return album[id].MusicIds;
    }

    /**
     * @notice Gifts an album to a user without payment
     * @dev Only callable by owner. Marks the album as gifted to the user and
     *      increments the purchase counter. For special editions, validates that
     *      max supply has not been reached. Reverts if: user already owns album,
     *      album is banned, or special edition max supply reached.
     * @param id The album ID to gift
     * @param userId The unique identifier of the recipient user
     * @return Array of song IDs included in the gifted album
     */
    function gift(
        uint256 id,
        uint256 userId
    )
        external
        onlyOwner
        onlyIfNotBanned(id)
        onlyIfExist(id)
        returns (uint256[] memory)
    {
        if (ownByUserId[id][userId] != 0x00) revert UserAlreadyOwns();
        if (album[id].IsASpecialEdition) {
            if (album[id].TimesBought >= album[id].MaxSupplySpecialEdition) {
                revert AlbumMaxSupplyReached();
            }
        }
        ownByUserId[id][userId] = 0x02;
        album[id].TimesBought++;
        album[id].listOfOwners.push(userId);
        ownerIndex[id][userId] = album[id].listOfOwners.length;

        emit Gifted(id, userId, block.timestamp);

        return album[id].MusicIds;
    }

    /**
     * @notice Processes a refund for a previously purchased album
     * @dev Only callable by owner. Reverts if user hasn't purchased the album.
     *      Uses a swap-and-pop algorithm for O(1) removal from the listOfOwners array:
     *      1. Retrieve the user's position from ownerIndex (stored as position + 1)
     *      2. Swap the user with the last element in the array
     *      3. Update the swapped user's index in ownerIndex
     *      4. Pop the last element (now the removed user)
     *      5. Clean up mappings and decrement TimesBought
     * @param id The album ID to refund
     * @param userId The unique identifier of the user requesting refund
     * @return Array of song IDs included in the refunded album
     */
    function refund(
        uint256 id,
        uint256 userId
    ) external onlyOwner onlyIfExist(id) returns (uint256[] memory) {
        /// @dev Retrieve the stored index (1-indexed to distinguish from "not found")
        uint256 ownerSlotPlusOne = ownerIndex[id][userId];
        /// @dev If ownerSlotPlusOne is 0, the user was never added to the list
        if (ownerSlotPlusOne == 0) revert UserNotOwnedAlbum();

        /// @dev Convert to 0-indexed position for array access
        uint256 ownerSlot = ownerSlotPlusOne - 1;

        /// @dev Get the last element's index and value for the swap operation
        uint256 lastIndex = album[id].listOfOwners.length - 1;
        uint256 lastUser = album[id].listOfOwners[lastIndex];

        /// @dev Swap-and-pop: Only swap if the user is not already the last element
        if (ownerSlot != lastIndex) {
            /// @dev Move the last user to the position of the user being removed
            album[id].listOfOwners[ownerSlot] = lastUser;
            /// @dev Update the moved user's index in the mapping (store as 1-indexed)
            ownerIndex[id][lastUser] = ownerSlot + 1;
        }

        /// @dev Remove the last element (either the removed user or the duplicate after swap)
        album[id].listOfOwners.pop();

        /// @dev Clean up the removed user's index tracking
        delete ownerIndex[id][userId];
        /// @dev Remove ownership status from the user
        delete ownByUserId[id][userId];

        /// @dev Decrement the total purchase counter
        album[id].TimesBought--;

        emit Refunded(id, userId, block.timestamp);

        return (album[id].MusicIds);
    }

    /**
     * @notice Updates all metadata fields for an existing album
     * @dev Only callable by owner. Preserves TimesBought and IsBanned status.
     *      Reverts if musicIds is empty.
     * @param id The album ID to update
     * @param title New display name for the album
     * @param principalArtistId New principal artist ID
     * @param metadataURI New URI for off-chain metadata
     * @param musicIds New array of song IDs (cannot be empty)
     * @param price New net purchase price. Additional fees and taxes may apply separately.
     * @param canBePurchased New purchasability status
     * @param isASpecialEdition New special edition status
     * @param specialEditionName New special edition name
     * @param maxSupplySpecialEdition New max supply for special edition
     */
    function change(
        uint256 id,
        string calldata title,
        uint256 principalArtistId,
        string calldata metadataURI,
        uint256[] calldata musicIds,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string calldata specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        if (musicIds.length == 0) revert AlbumCannotHaveZeroSongs();

        _clearAndValidateSongs(id, musicIds);

        album[id] = Metadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            MetadataURI: metadataURI,
            MusicIds: musicIds,
            Price: price,
            TimesBought: album[id].TimesBought,
            CanBePurchased: canBePurchased,
            IsASpecialEdition: isASpecialEdition,
            SpecialEditionName: specialEditionName,
            MaxSupplySpecialEdition: maxSupplySpecialEdition,
            listOfOwners: album[id].listOfOwners,
            IsBanned: album[id].IsBanned
        });

        emit Changed(id, block.timestamp, ChangeType.MetadataUpdated);
    }

    /**
     * @notice Updates the purchasability status of an album
     * @dev Only callable by owner. Cannot modify banned albums.
     * @param id The album ID to update
     * @param canBePurchased New purchasability status (true = available for sale)
     */
    function changePurchaseability(
        uint256 id,
        bool canBePurchased
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        album[id].CanBePurchased = canBePurchased;

        emit Changed(id, block.timestamp, ChangeType.PurchaseabilityChanged);
    }

    /**
     * @notice Updates the net price of an album
     * @dev Only callable by owner. Cannot modify banned albums.
     *      This is the net price; fees and taxes are separate.
     * @param id The album ID to update
     * @param price New net purchase price for the album
     */
    function changePrice(
        uint256 id,
        uint256 price
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        album[id].Price = price;

        emit Changed(id, block.timestamp, ChangeType.PriceChanged);
    }

    /**
     * @notice Sets the banned status of an album
     * @dev Only callable by owner. Banned albums cannot be purchased or modified.
     * @param id The album ID to update
     * @param isBanned New banned status (true = banned from platform)
     */
    function setBannedStatus(
        uint256 id,
        bool isBanned
    ) external onlyOwner onlyIfExist(id) {
        album[id].IsBanned = isBanned;

        if (isBanned) emit Banned(id);
        else emit Unbanned(id);
    }

    /**
     * @notice Sets the public visibility of the album owners list
     * @dev Only callable by owner. If set to false, only the owner (Orchestrator)
     *      can view the full list of album owners.
     * @param isVisible New visibility status (true = publicly visible)
     */
    function setListVisibility(bool isVisible) external onlyOwner {
        listVisibility = isVisible;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Getter Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Checks if a user has already purchased an album
     * @dev Returns true if the user has bought the album (useful before attempting purchase)
     * @param id The album ID to check
     * @param userId The user ID to check
     * @return True if the user has purchased the album, false otherwise
     */
    function isUserOwner(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return ownByUserId[id][userId] != 0x00;
    }

    /**
     * @notice Retrieves the ownership status byte for a user and album
     * @dev Returns 0x00 (not owned), 0x01 (bought), or 0x02 (gifted)
     * @param id The album ID to check
     * @param userId The user ID to check
     * @return The ownership status byte
     */
    function userOwnershipStatus(
        uint256 id,
        uint256 userId
    ) external view returns (bytes1) {
        return ownByUserId[id][userId];
    }

    /**
     * @notice Checks if an album is a special edition
     * @param id The album ID to query
     * @return True if the album is a special edition, false otherwise
     */
    function isAnSpecialEdition(uint256 id) external view returns (bool) {
        return album[id].IsASpecialEdition;
    }

    /**
     * @notice Gets the total number of times an album has been purchased if
     *         is a special edition
     * @param id The album ID to query
     * @return The total purchase count for the album
     *
     * @notice if the album is not a special edition, this returns 0
     */
    function getTotalSupply(uint256 id) external view returns (uint256) {
        return album[id].TimesBought;
    }

    /**
     * @notice Gets the current net price of an album
     * @param id The album ID to query
     * @return The net price of the album in wei or token units (does not include fees or taxes)
     */
    function getPrice(uint256 id) external view returns (uint256) {
        return album[id].Price;
    }

    /**
     * @notice Checks if an album is available for purchase
     * @param id The album ID to query
     * @return True if the album can be purchased, false otherwise
     */
    function isPurchasable(uint256 id) external view returns (bool) {
        return album[id].CanBePurchased;
    }

    /**
     * @notice Gets the principal artist ID for an album
     * @param id The album ID to query
     * @return The unique identifier of the principal artist
     */
    function getPrincipalArtistId(uint256 id) external view returns (uint256) {
        return album[id].PrincipalArtistId;
    }

    /**
     * @notice Checks if an album is banned from the platform
     * @param id The album ID to query
     * @return True if the album is banned, false otherwise
     */
    function checkIsBanned(uint256 id) external view returns (bool) {
        return album[id].IsBanned;
    }

    /**
     * @notice Retrieves all metadata for an album
     * @param id The album ID to query
     * @return Complete Metadata struct with all album information
     */
    function getMetadata(uint256 id) external view returns (Metadata memory) {
        return album[id];
    }

    /**
     * @notice Retrieves the full list of user IDs that own a specific album
     * @dev Respects the listVisibility setting; reverts if visibility is disabled
     *      and caller is not the owner (Orchestrator).
     * @param id The album ID to query
     * @return Array of user IDs owning the album
     */
    function getListOfOwners(
        uint256 id
    ) external view returns (uint256[] memory) {
        if (!listVisibility && msg.sender != owner())
            revert CannotSeeListOfOwners();

        return album[id].listOfOwners;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Private Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Clears previous song assignments and validates new song IDs
     * @dev Used during album updates to ensure no duplicate song usage across albums
     *      Reverts if any new song ID is already assigned to another album.
     * @param id The album ID being updated
     * @param musicIds New array of song IDs to validate
     */
    function _clearAndValidateSongs(uint256 id, uint256[] memory musicIds) private {
        for (uint256 i = 0; i < album[id].MusicIds.length; i++) {
            delete songUsedInAlbum[album[id].MusicIds[i]];
        }
        _validateSongs(musicIds);
    }

    /**
     * @notice Validates that song IDs are not already used in other albums
     * @dev Reverts if any song ID is found to be already assigned
     * @param musicIds Array of song IDs to validate
     */
    function _validateSongs(uint256[] memory musicIds) private view {
        for (uint256 i = 0; i < musicIds.length; i++) {
            if (songUsedInAlbum[musicIds[i]] != 0)
                revert SongAlreadyUsedInAlbum(musicIds[i]);
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
