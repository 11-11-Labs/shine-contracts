// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine UserDB
 * @author 11:11 Labs 
 * @notice This contract serves as a database for storing and managing user profiles and data,
 *         including user registration, purchase history, balance tracking, and profile management
 *         for the Shine music platform.
 * @dev Inherits from IdUtils for unique ID generation and Ownable for access control.
 *      Only the Orchestrator contract (owner) can modify state.
 */

import {IdUtils} from "@shine/library/IdUtils.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract UserDB is IdUtils, Ownable {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @dev Thrown when attempting to interact with a banned user
    error UserIsBanned();
    /// @dev Thrown when attempting to access a user that does not exist
    error UserDoesNotExist();
    /// @dev Thrown when trying to set a username to empty string
    error UsernameIsEmpty();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Type Declarations 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Stores all metadata associated with a user
     * @dev Used to track user profile information, purchase history, and account status
     * @param Username The display name/username of the user
     * @param MetadataURI URI pointing to off-chain metadata (e.g., IPFS)
     * @param Address The wallet address associated with this user
     * @param PurchasedSongIds Array of song IDs purchased by this user
     * @param Balance Current balance of the user account
     * @param IsBanned Flag indicating if the user has been banned from the platform
     */
    struct Metadata {
        string Username;
        string MetadataURI;
        address Address;
        uint256[] PurchasedSongIds;
        uint256 Balance;
        uint256 AccumulatedRoyalties;
        bool IsBanned;
    }

    /**
     * @notice Enum representing types of metadata changes for a user
     * @dev Used in events to indicate what type of data was modified
     */
    enum ChangeType {
        MetadataUpdated,
        AddressUpdated
    }

    /**
     * @notice Enum representing types of balance changes for a user
     * @dev Used in events to indicate whether balance was added or deducted
     */
    enum BalanceChangeType {
        Added,
        Deducted
    }

    /**
     * @notice Enum representing types of song list changes for a user
     * @dev Used in events to indicate whether songs were added or removed
     */
    enum SongListChangeType {
        Added,
        Removed
    }


    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 State Variables 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Maps user wallet addresses to their unique IDs
     * @dev Provides quick lookup of user ID by their Ethereum address
     */
    mapping(address userAddress => uint256 id) private addressUser;

    /**
     * @notice Stores all user metadata indexed by user ID
     * @dev Private mapping to prevent direct external access
     */
    mapping(uint256 Id => Metadata) private users;

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Events 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Emitted when a new user is registered in the database
     * @param userId The unique identifier assigned to the user
     * @param userAddress The wallet address of the registered user
     */
    event Registered(uint256 indexed userId, address indexed userAddress);

    /**
     * @notice Emitted when user metadata or address is updated
     * @param userId The unique identifier of the modified user
     * @param changeType The type of change that occurred
     */
    event Changed(uint256 indexed userId, ChangeType indexed changeType);

    /**
     * @notice Emitted when a single song is added or removed from a user's purchase list
     * @param userId The unique identifier of the user
     * @param songId The unique identifier of the song
     * @param changeType Whether the song was added or removed
     */
    event SongListChangedSingle(
        uint256 indexed userId,
        uint256 indexed songId,
        SongListChangeType indexed changeType
    );

    /**
     * @notice Emitted when multiple songs are added or removed from a user's purchase list
     * @param userId The unique identifier of the user
     * @param songIds Array of song IDs that were modified
     * @param changeType Whether songs were added or removed
     */
    event SongListChangedBatch(
        uint256 indexed userId,
        uint256[] songIds,
        SongListChangeType indexed changeType
    );

    /**
     * @notice Emitted when a user's balance is modified
     * @param userId The unique identifier of the user
     * @param amountChanged The amount that was added or deducted
     * @param changeType Whether balance was added or deducted
     */
    event BalanceChanged(
        uint256 indexed userId,
        uint256 indexed amountChanged,
        BalanceChangeType indexed changeType
    );

    /**
     * @notice Emitted when an artist's accumulated royalties are modified
     * @param artistId The unique identifier of the artist
     * @param amountChanged The amount of royalties added or deducted
     * @param changeType Whether royalties were added or deducted
     */
    event AccumulatedRoyaltiesChanged(
        uint256 indexed artistId,
        uint256 indexed amountChanged,
        BalanceChangeType indexed changeType
    );

    /**
     * @notice Emitted when a user is banned from the platform
     * @param userId The unique identifier of the banned user
     */
    event Banned(uint256 indexed userId);

    /**
     * @notice Emitted when a user ban is lifted
     * @param userId The unique identifier of the unbanned user
     */
    event Unbanned(uint256 indexed userId);

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Modifiers 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Ensures the user exists before executing the function
     * @dev Reverts with UserDoesNotExist if the user ID is not registered
     * @param id The user ID to validate
     */
    modifier onlyIfExist(uint256 id) {
        if (!exists(id)) revert UserDoesNotExist();
        _;
    }

    /**
     * @notice Ensures the user is not banned before executing the function
     * @dev Reverts with UserIsBanned if the user has been banned
     * @param id The user ID to validate
     */
    modifier onlyIfNotBanned(uint256 id) {
        if (users[id].IsBanned) revert UserIsBanned();
        _;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Constructor 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Initializes the UserDB contract
     * @dev Sets the Orchestrator contract as the owner for access control
     * @param _orchestratorAddress Address of the Orchestrator contract that will manage this database
     */
    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 External Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Registers a new user in the database
     * @dev Only callable by the Orchestrator (owner). Assigns a unique ID automatically.
     * @param username The display username of the user
     * @param metadataURI URI pointing to off-chain metadata (e.g., IPFS hash)
     * @param userAddress The wallet address of the user
     * @return The newly assigned user ID
     */
    function register(
        string memory username,
        string memory metadataURI,
        address userAddress
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        users[idAssigned] = Metadata({
            Username: username,
            MetadataURI: metadataURI,
            Address: userAddress,
            PurchasedSongIds: new uint256[](0),
            Balance: 0,
            AccumulatedRoyalties: 0,
            IsBanned: false
        });

        addressUser[userAddress] = idAssigned;

        emit Registered(idAssigned, userAddress);

        return idAssigned;
    }

    /**
     * @notice Updates basic user information (username and metadata)
     * @dev Only callable by owner. Cannot modify banned users. Username cannot be empty.
     * @param id The user ID to update
     * @param username New display username for the user
     * @param metadataURI New URI for off-chain metadata
     */
    function changeBasicData(
        uint256 id,
        string memory username,
        string memory metadataURI
    ) external onlyOwner onlyIfExist(id) onlyIfNotBanned(id) {
        if (bytes(username).length == 0) revert UsernameIsEmpty();

        users[id].Username = username;
        users[id].MetadataURI = metadataURI;

        emit Changed(id, ChangeType.MetadataUpdated);
    }

    /**
     * @notice Updates the wallet address associated with a user
     * @dev Only callable by owner. Updates both direction mappings.
     * @param id The user ID to update
     * @param newAddress New wallet address for the user
     */
    function changeAddress(
        uint256 id,
        address newAddress
    ) external onlyOwner onlyIfExist(id) onlyIfNotBanned(id) {
        addressUser[users[id].Address] = 0;
        users[id].Address = newAddress;
        addressUser[newAddress] = id;

        emit Changed(id, ChangeType.AddressUpdated);
    }

    /**
     * @notice Adds a single song to a user's purchase history
     * @dev Only callable by owner. Cannot be called on banned users.
     * @param userId The user ID to update
     * @param songId The song ID to add to purchases
     */
    function addSong(
        uint256 userId,
        uint256 songId
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        users[userId].PurchasedSongIds.push(songId);

        emit SongListChangedSingle(
            userId,
            songId,
            SongListChangeType.Added
        );
    }

    /**
     * @notice Removes a single song from a user's purchase history
     * @dev Only callable by owner. Uses optimized removal algorithm.
     * @param userId The user ID to update
     * @param songId The song ID to remove from purchases
     */
    function deleteSong(
        uint256 userId,
        uint256 songId
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        uint256[] storage songIds = users[userId].PurchasedSongIds;
        uint256 len = songIds.length;

        for (uint256 i; i < len; ) {
            if (songIds[i] == songId) {
                for (uint256 j = i; j < len - 1; ) {
                    songIds[j] = songIds[j + 1];
                    unchecked {
                        ++j;
                    }
                }
                songIds.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }

        emit SongListChangedSingle(
            userId,
            songId,
            SongListChangeType.Removed
        );
    }

    /**
     * @notice Adds multiple songs to a user's purchase history
     * @dev Only callable by owner. Cannot be called on banned users.
     * @param userId The user ID to update
     * @param songIds Array of song IDs to add to purchases
     */
    function addSongs(
        uint256 userId,
        uint256[] calldata songIds
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        uint256 len = songIds.length;
        for (uint256 i; i < len; ) {
            users[userId].PurchasedSongIds.push(songIds[i]);
            unchecked {
                ++i;
            }
        }

        emit SongListChangedBatch(
            userId,
            songIds,
            SongListChangeType.Added
        );
    }

    /**
     * @notice Removes multiple songs from a user's purchase history
     * @dev Only callable by owner. Uses optimized removal algorithm.
     * @param userId The user ID to update
     * @param songIdsToDelete Array of song IDs to remove from purchases
     */
    function deleteSongs(
        uint256 userId,
        uint256[] calldata songIdsToDelete
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        uint256[] storage songIds = users[userId].PurchasedSongIds;
        uint256 len = songIds.length;
        uint256 deleteLen = songIdsToDelete.length;

        uint256 writeIndex;

        for (uint256 i; i < len; ) {
            bool shouldDelete;

            // Verificar si el songId actual está en la lista de eliminación
            for (uint256 j; j < deleteLen; ) {
                if (songIds[i] == songIdsToDelete[j]) {
                    shouldDelete = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }

            // Si no se debe eliminar, mantenerlo
            if (!shouldDelete) {
                if (writeIndex != i) {
                    songIds[writeIndex] = songIds[i];
                }
                unchecked {
                    ++writeIndex;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Remover los elementos sobrantes al final
        while (songIds.length > writeIndex) {
            songIds.pop();
        }

        emit SongListChangedBatch(
            userId,
            songIdsToDelete,
            SongListChangeType.Removed
        );
    }

    /**
     * @notice Adds balance to a user account
     * @dev Only callable by owner. Cannot be called on banned users.
     * @param userId The user ID to credit
     * @param amount The amount to add to balance
     */
    function addBalance(
        uint256 userId,
        uint256 amount
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        users[userId].Balance += amount;

        emit BalanceChanged(
            userId,
            amount,
            BalanceChangeType.Added
        );
    }

    /**
     * @notice Deducts balance from a user account
     * @dev Only callable by owner. Cannot be called on banned users.
     * @param userId The user ID to debit
     * @param amount The amount to deduct from balance
     */
    function deductBalance(
        uint256 userId,
        uint256 amount
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        users[userId].Balance -= amount;

        emit BalanceChanged(
            userId,
            amount,
            BalanceChangeType.Deducted
        );
    }

    /**
     * @notice Adds accumulated royalties to an artist account
     * @dev Only callable by owner. Cannot be called on banned artists.
     * @param artistId The artist ID to credit
     * @param amount The amount of royalties to add
     */
    function addAccumulatedRoyalties(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner onlyIfExist(artistId) onlyIfNotBanned(artistId) {
        users[artistId].AccumulatedRoyalties += amount;

        emit AccumulatedRoyaltiesChanged(
            artistId,
            amount,
            BalanceChangeType.Added
        );
    }

    /**
     * @notice Deducts accumulated royalties from an artist account
     * @dev Only callable by owner.
     * @param artistId The artist ID to debit
     * @param amount The amount of royalties to deduct
     */
    function deductAccumulatedRoyalties(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner onlyIfExist(artistId) {
        users[artistId].AccumulatedRoyalties -= amount;

        emit AccumulatedRoyaltiesChanged(
            artistId,
            amount,
            BalanceChangeType.Deducted
        );
    }

    /**
     * @notice Sets the banned status of a user
     * @dev Only callable by owner. Banned users cannot have their data modified.
     * @param id The user ID to update
     * @param isBanned New banned status (true = banned from platform)
     */
    function setBannedStatus(
        uint256 id,
        bool isBanned
    ) external onlyOwner onlyIfExist(id) {
        users[id].IsBanned = isBanned;

        if (isBanned) emit Banned(id);
        else emit Unbanned(id);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Getter Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Retrieves all metadata for a user
     * @param id The user ID to query
     * @return Complete User struct with all information
     */
    function getMetadata(uint256 id) external view returns (Metadata memory) {
        return users[id];
    }

    /**
     * @notice Gets the wallet address associated with a user
     * @param id The user ID to query
     * @return The user's wallet address
     */
    function getAddress(uint256 id) external view returns (address) {
        return users[id].Address;
    }

    /**
     * @notice Gets the user ID for a given wallet address
     * @param userAddress The user's wallet address
     * @return The unique identifier of the user
     */
    function getId(address userAddress) external view returns (uint256) {
        return addressUser[userAddress];
    }

    /**
     * @notice Gets the current balance of a user
     * @param userId The user ID to query
     * @return The user's current balance
     */
    function getBalance(uint256 userId) external view returns (uint256) {
        return users[userId].Balance;
    }

    /**
     * @notice Gets all purchased songs for a user
     * @param userId The user ID to query
     * @return Array of song IDs purchased by the user
     */
    function getPurchasedSong(
        uint256 userId
    ) external view returns (uint256[] memory) {
        return users[userId].PurchasedSongIds;
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