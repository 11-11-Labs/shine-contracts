// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine Orchestrator
 * @author 11:11 Labs 
 * @notice Central orchestration contract that coordinates all interactions with database contracts
 *         (AlbumDB, ArtistDB, SongDB, UserDB). Manages user/artist registration, purchases, 
 *         payments, donations, and administrative functions for the Shine music platform.
 * @dev Acts as the sole owner of all database contracts, enforcing access control and ensuring
 *      consistent business logic across the platform. Handles stablecoin payments, fee collection,
 *      and orchestrates complex multi-contract transactions.
 */

import {Ownable} from "@solady/auth/Ownable.sol";
import {IERC20} from "@shine/library/IERC20.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";
import {StructsLib} from "@shine/contracts/orchestrator/library/StructsLib.sol";
import {EventsLib} from "@shine/contracts/orchestrator/library/EventsLib.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";

contract Orchestrator is Ownable {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 State Variables 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /// @notice Address of the next Orchestrator contract in case of migration
    address private newOrchestratorAddress;

    /// @notice Total amount of platform fees collected from transactions
    uint256 private amountCollectedInFees;

    /// @notice Current and proposed stablecoin addresses with timelock for upgrades
    StructsLib.AddressProposal private stablecoin;

    /// @notice Addresses of all database contracts (Album, Artist, Song, User)
    StructsLib.DataBaseList private dbAddress;

    /// @notice Operational breaker flags for initialization and state control
    StructsLib.Breakers private breaker;

    /// @notice Platform fee percentage in basis points (100 = 1%, 10000 = 100%)
    uint16 private percentageFee;

    /// @notice Contract references to all database contracts
    SongDB private songDB;
    AlbumDB private albumDB;
    UserDB private userDB;

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Modifiers 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Validates that the sender is the owner of the specified user ID
     * @param userId The user ID to validate against the sender
     */
    modifier senderIsUserId(uint256 userId) {
        if (userDB.getAddress(userId) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfUserId();
        _;
    }

    /**
     * @notice Validates that the specified user ID exists
     * @param userId The user ID to check for existence
     */
    modifier userIdExists(uint256 userId) {
        if (!userDB.exists(userId)) revert ErrorsLib.UserIdDoesNotExist(userId);
        _;
    }

    /**
     * @notice Validates that the specified song ID exists
     * @param songId The song ID to check for existence
     */
    modifier songIdExists(uint256 songId) {
        if (!songDB.exists(songId)) revert ErrorsLib.SongIdDoesNotExist(songId);
        _;
    }

    /**
     * @notice Validates that the specified album ID exists
     * @param albumId The album ID to check for existence
     */
    modifier albumIdExists(uint256 albumId) {
        if (!albumDB.exists(albumId)) revert();
        _;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Constructor 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Initializes the Orchestrator contract with owner, stablecoin, and fee settings
     * @dev Sets the initial owner, stablecoin token, and platform fee percentage used for all platform transactions
     * @param initialOwner Address that will have owner privileges for administrative functions
     * @param _stablecoinAddress Address of the stablecoin ERC20 token used for payments
     * @param _percentageFee Platform fee percentage in basis points (100 = 1%, 10000 = 100%)
     */
    constructor(
        address initialOwner,
        address _stablecoinAddress,
        uint16 _percentageFee
    ) {
        _initializeOwner(initialOwner);
        stablecoin.current = _stablecoinAddress;
        percentageFee = _percentageFee;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 User/Artist Registration 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Registers a new user in the platform
     * @param name The display name for the user
     * @param metadataURI URI pointing to off-chain profile metadata (e.g., IPFS)
     * @param addressToUse The blockchain address associated with this user
     * @return The newly assigned ID for the registered user
     */
    function register(
        string memory name,
        string memory metadataURI,
        address addressToUse
    ) external returns (uint256) {
        return userDB.register(name, metadataURI, addressToUse);
    }

    /**
     * @notice Updates basic profile data for a user
     * @dev Only the owner of the ID can update their own profile
     * @param id The user ID to update
     * @param name New display name
     * @param metadataURI New metadata URI for profile information
     */
    function chnageBasicData(
        uint256 id,
        string memory name,
        string memory metadataURI
    ) external {
        if (userDB.getAddress(id) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfUserId();

        userDB.changeBasicData(id, name, metadataURI);
    }

    /**
     * @notice Changes the blockchain address associated with a user account
     * @dev Only the current owner of the ID can change the address. Enables address transfers.
     * @param id The user ID whose address to change
     * @param newAddress The new blockchain address to associate with this account
     */
    function changeAddress(uint256 id, address newAddress) external {
        if (userDB.getAddress(id) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfUserId();

        userDB.changeAddress(id, newAddress);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Fund Management 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Deposits stablecoin funds into a user's account balance
     * @dev Only the user owner can deposit into their own account. Requires prior token approval.
     * @param userId The user ID to receive the deposited funds
     * @param amount The amount of stablecoin to deposit (in token units)
     */
    function depositFunds(uint256 userId, uint256 amount) external {
        if (userDB.getAddress(userId) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfUserId();

        IERC20(stablecoin.current).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        userDB.addBalance(userId, amount);
    }

    /**
     * @notice Deposits stablecoin funds into another user's account (e.g., gift of funds)
     * @dev Any address can deposit funds to any valid user. Requires prior token approval.
     * @param toUserId The recipient user ID
     * @param amount The amount of stablecoin to deposit (in token units)
     */
    function depositFundsToAnotherUser(
        uint256 toUserId,
        uint256 amount
    ) external userIdExists(toUserId) {
        IERC20(stablecoin.current).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        userDB.addBalance(toUserId, amount);
    }

    /**
     * @notice Allows a user to donate funds directly to another user (artist)
     * @dev Transfers funds from user balance to another user's balance. User must have sufficient balance.
     * @param userId The ID of the user making the donation
     * @param toUserId The ID of the user receiving the donation
     * @param amount The donation amount in stablecoin units
     */
    function makeDonation(
        uint256 userId,
        uint256 toUserId,
        uint256 amount
    ) external senderIsUserId(userId) userIdExists(toUserId) {
        if (userDB.getBalance(userId) < amount)
            revert ErrorsLib.InsufficientBalance();

        userDB.deductBalance(userId, amount);
        userDB.addBalance(toUserId, amount);

        emit EventsLib.DonationMade(userId, toUserId, amount);
    }

    /**
     * @notice Withdraws stablecoin funds from a user/artist account to their blockchain address
     * @dev Only the owner of the account can withdraw. Requires sufficient balance.
     * @param userId The artist/user ID to withdraw from
     * @param amount The amount of stablecoin to withdraw
     */
    function withdrawFunds(uint256 userId, uint256 amount) external {
        if (userDB.getAddress(userId) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfUserId();

        if (userDB.getBalance(userId) < amount)
            revert ErrorsLib.InsufficientBalance();

        userDB.deductBalance(userId, amount);

        IERC20(stablecoin.current).transfer(msg.sender, amount);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Song Management 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Registers a new song to the platform
     * @dev Only the principal artist can register songs. Validates all featured artists exist.
     *      Validates title is not empty. Song price should be the net artist rate.
     * @param title Display name of the song
     * @param principalArtistId The main artist ID (must be the sender)
     * @param artistIDs Array of featured artist IDs (can be empty)
     * @param mediaURI URI pointing to the song audio/media (e.g., IPFS or CDN)
     * @param metadataURI URI pointing to song metadata (e.g., IPFS)
     * @param canBePurchased Whether the song is available for purchase
     * @param netprice The net artist price (before platform fees)
     * @return The newly assigned song ID
     */
    function registerSong(
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 netprice
    ) external senderIsUserId(principalArtistId) returns (uint256) {
        if (artistIDs.length > 0) {
            for (uint256 i = 0; i < artistIDs.length; i++) {
                if (!userDB.exists(artistIDs[i]))
                    revert ErrorsLib.UserIdDoesNotExist(artistIDs[i]);
            }
        }

        if (bytes(title).length == 0) revert ErrorsLib.TitleCannotBeEmpty();

        return
            songDB.register(
                title,
                principalArtistId,
                artistIDs,
                mediaURI,
                metadataURI,
                canBePurchased,
                netprice
            );
    }

    /**
     * @notice Updates all metadata for an existing song
     * @dev Only the principal artist can update. Cannot modify principal artist.
     * @param id The song ID to update
     * @param title New song title
     * @param artistIDs New featured artists array
     * @param mediaURI New media URI
     * @param metadataURI New metadata URI
     * @param canBePurchased New purchasability status
     * @param price New net artist price
     */
    function changeSongFullData(
        uint256 id,
        string memory title,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external senderIsUserId(songDB.getPrincipalArtistId(id)) {
        if (artistIDs.length > 0) {
            for (uint256 i = 0; i < artistIDs.length; i++) {
                if (!userDB.exists(artistIDs[i]))
                    revert ErrorsLib.UserIdDoesNotExist(artistIDs[i]);
            }
        }

        if (bytes(title).length == 0) revert ErrorsLib.TitleCannotBeEmpty();

        songDB.change(
            id,
            title,
            songDB.getPrincipalArtistId(id),
            artistIDs,
            mediaURI,
            metadataURI,
            canBePurchased,
            price
        );
    }

    /**
     * @notice Updates whether a song is available for purchase
     * @dev Only the principal artist can modify purchasability
     * @param songId The song ID to update
     * @param canBePurchased New purchasability status
     */
    function changeSongPurchaseability(
        uint256 songId,
        bool canBePurchased
    ) external senderIsUserId(songDB.getPrincipalArtistId(songId)) {
        songDB.changePurchaseability(songId, canBePurchased);
    }

    /**
     * @notice Updates the net price of a song
     * @dev Only the principal artist can modify pricing
     * @param songId The song ID to update
     * @param price New net artist price (before platform fees)
     */
    function changeSongPrice(
        uint256 songId,
        uint256 price
    ) external senderIsUserId(songDB.getPrincipalArtistId(songId)) {
        songDB.changePrice(songId, price);
    }

    /**
     * @notice Processes a song purchase for a user
     * @dev Caller must have sufficient balance to cover price + fees. Adds song to user's library.
     *      Transfers net price to artist and collects platform fees.
     * @param songId The song ID to purchase
     * @param extraAmount Optional tip/extra amount beyond the song price (sent to artist)
     */
    function purchaseSong(uint256 songId, uint256 extraAmount) external {
        uint256 userID = userDB.getId(msg.sender);
        songDB.purchase(songId, userID);
        userDB.addSong(userID, songId);

        uint256 netPrice = songDB.getPrice(songId);

        if (netPrice + extraAmount > 0)
            _executePayment(
                userID,
                songDB.getPrincipalArtistId(songId),
                netPrice,
                extraAmount
            );

        emit EventsLib.SongPurchased(songId, userID, netPrice);
    }

    /**
     * @notice Gifts a song to a user without requiring payment
     * @dev Only the principal artist can gift their songs
     * @param songId The song ID to gift
     * @param toUserId The user ID to receive the gift
     */
    function giftSong(
        uint256 songId,
        uint256 toUserId
    ) external senderIsUserId(songDB.getPrincipalArtistId(songId)) {
        songDB.gift(songId, toUserId);
        userDB.addSong(toUserId, songId);

        emit EventsLib.SongGifted(songId, toUserId);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Album Management 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Registers a new album to the platform
     * @dev Only the principal artist can register albums. All songs must belong to the same principal artist.
     *      For special editions, maxSupplySpecialEdition and specialEditionName must be provided.
     * @param title Display name of the album
     * @param principalArtistId The main artist ID (must be the sender)
     * @param metadataURI URI pointing to album metadata (e.g., IPFS)
     * @param songIDs Array of song IDs to include in the album
     * @param price The net album price (before platform fees)
     * @param canBePurchased Whether the album is available for purchase
     * @param isASpecialEdition Whether this is a limited edition release
     * @param specialEditionName Name/label for the special edition
     * @param maxSupplySpecialEdition Maximum copies available (0 if not special edition)
     * @return The newly assigned album ID
     */
    function registerAlbum(
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external senderIsUserId(principalArtistId) returns (uint256) {
        if (bytes(title).length == 0) revert ErrorsLib.TitleCannotBeEmpty();

        if (isASpecialEdition) {
            if (maxSupplySpecialEdition == 0)
                revert ErrorsLib.MaxSupplyMustBeGreaterThanZero();

            if (bytes(specialEditionName).length == 0)
                revert ErrorsLib.SpecialEditionNameCannotBeEmpty();
        }

        for (uint256 i = 0; i < songIDs.length; i++) {
            if (!songDB.exists(songIDs[i]))
                revert ErrorsLib.SongIdDoesNotExist(songIDs[i]);

            if (songDB.getPrincipalArtistId(songIDs[i]) != principalArtistId)
                revert ErrorsLib.ListCannotContainSongsFromDifferentPrincipalArtist();
        }

        return
            albumDB.register(
                title,
                principalArtistId,
                metadataURI,
                songIDs,
                price,
                canBePurchased,
                isASpecialEdition,
                specialEditionName,
                maxSupplySpecialEdition
            );
    }

    /**
     * @notice Updates all metadata for an existing album
     * @dev Only the principal artist can update. Cannot increase special edition supply below current sales.
     * @param id The album ID to update
     * @param title New album title
     * @param principalArtistId Principal artist (must remain the same)
     * @param metadataURI New metadata URI
     * @param musicIds New array of song IDs
     * @param price New net album price
     * @param canBePurchased New purchasability status
     * @param specialEditionName Name for special edition
     * @param maxSupplySpecialEdition Maximum supply for special edition
     */
    function changeAlbumFullData(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory musicIds,
        uint256 price,
        bool canBePurchased,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external senderIsUserId(albumDB.getPrincipalArtistId(id)) {
        if (
            albumDB.isAnSpecialEdition(id) &&
            maxSupplySpecialEdition <= albumDB.getTotalSupply(id)
        ) revert ErrorsLib.MustBeGreaterThanCurrent();

        bool isSpecialEdition = albumDB.isAnSpecialEdition(id);

        albumDB.change(
            id,
            title,
            principalArtistId,
            metadataURI,
            musicIds,
            price,
            canBePurchased,
            isSpecialEdition,
            isSpecialEdition ? specialEditionName : "",
            isSpecialEdition ? maxSupplySpecialEdition : 0
        );
    }

    /**
     * @notice Updates whether an album is available for purchase
     * @dev Only the principal artist can modify purchasability
     * @param albumId The album ID to update
     * @param canBePurchased New purchasability status
     */
    function changeAlbumPurchaseability(
        uint256 albumId,
        bool canBePurchased
    ) external senderIsUserId(albumDB.getPrincipalArtistId(albumId)) {
        albumDB.changePurchaseability(albumId, canBePurchased);
    }

    /**
     * @notice Updates the net price of an album
     * @dev Only the principal artist can modify pricing
     * @param albumId The album ID to update
     * @param price New net album price (before platform fees)
     */
    function changeAlbumPrice(
        uint256 albumId,
        uint256 price
    ) external senderIsUserId(albumDB.getPrincipalArtistId(albumId)) {
        albumDB.changePrice(albumId, price);
    }

    /**
     * @notice Processes an album purchase for a user
     * @dev Caller must have sufficient balance to cover price + fees. Adds all songs to user's library.
     *      Transfers net price to artist and collects platform fees.
     * @param albumId The album ID to purchase
     * @param extraAmount Optional tip/extra amount beyond the album price (sent to artist)
     */
    function purchaseAlbum(uint256 albumId, uint256 extraAmount) external {
        uint256 userID = userDB.getId(msg.sender);

        uint[] memory listOfSong = albumDB.purchase(albumId, userID);
        userDB.addSongs(userID, listOfSong);

        _executePayment(
            userID,
            albumDB.getPrincipalArtistId(albumId),
            albumDB.getPrice(albumId),
            extraAmount
        );

        emit EventsLib.AlbumPurchased(
            albumId,
            userID,
            albumDB.getPrice(albumId)
        );
    }

    /**
     * @notice Gifts an album to a user without requiring payment
     * @dev Only the principal artist can gift their albums
     * @param albumId The album ID to gift
     * @param toUserId The user ID to receive the gift
     */
    function giftAlbum(
        uint256 albumId,
        uint256 toUserId
    ) external senderIsUserId(albumDB.getPrincipalArtistId(albumId)) {
        uint[] memory listOfSong = albumDB.gift(albumId, toUserId);
        userDB.addSongs(toUserId, listOfSong);

        emit EventsLib.AlbumGifted(albumId, toUserId);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Administrative Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Initializes the database contract addresses for the Orchestrator
     * @dev Can only be called once. Sets up references to all four database contracts.
     *      After this, cannot be changed without migration.
     * @param _dbalbum Address of the AlbumDB contract
     * @param _dbsong Address of the SongDB contract
     * @param _dbuser Address of the UserDB contract
     */
    function setDatabaseAddresses(
        address _dbalbum,
        address _dbsong,
        address _dbuser
    ) external onlyOwner {
        if (breaker.addressSetup != bytes1(0x00))
            revert ErrorsLib.AddressSetupAlreadyDone();

        dbAddress.album = _dbalbum;
        dbAddress.song = _dbsong;
        dbAddress.user = _dbuser;

        songDB = SongDB(_dbsong);
        albumDB = AlbumDB(_dbalbum);
        userDB = UserDB(_dbuser);
        breaker.addressSetup = bytes1(0x01);
    }

    /**
     * @notice Change the platform fee percentage
     * @dev Fees are specified in basis points (100 = 1%, 10000 = 100%)
     *      Fee is applied to all song and album purchases, but not to donations.
     * @param _percentageFee Fee percentage in basis points (max 10000)
     */
    function changePercentageFee(uint16 _percentageFee) external onlyOwner {
        /// @dev percentage fee is in basis points (100 = 1%)
        if (_percentageFee > 10000) revert ErrorsLib.InvalidPercentageFee(); // max 100%
        percentageFee = _percentageFee;
    }

    /**
     * @notice Proposes a new stablecoin address with a 1-day timelock
     * @dev Requires executeStablecoinAddressChange() to be called after the timelock expires.
     *      Reverts if the proposed address is the zero address.
     * @param newStablecoinAddress The new stablecoin ERC20 token address
     */
    function proposeStablecoinAddressChange(
        address newStablecoinAddress
    ) external onlyOwner {
        if (newStablecoinAddress == address(0))
            revert ErrorsLib.ProposedAddressCannotBeZero();

        stablecoin.proposed = newStablecoinAddress;
        stablecoin.timeToExecute = block.timestamp + 1 days;
    }

    /**
     * @notice Cancels a pending stablecoin address change
     * @dev Clears the proposed address and timelock
     */
    function cancelStablecoinAddressChange() external onlyOwner {
        stablecoin.proposed = address(0);
        stablecoin.timeToExecute = 0;
    }

    /**
     * @notice Executes a previously proposed stablecoin address change
     * @dev Can only be called after the 1-day timelock has expired.
     *      Reverts if no proposal exists or if the timelock has not yet expired.
     */
    function executeStablecoinAddressChange() external onlyOwner {
        if (block.timestamp < stablecoin.timeToExecute)
            revert ErrorsLib.TimelockNotExpired();

        stablecoin = StructsLib.AddressProposal({
            current: stablecoin.proposed,
            proposed: address(0),
            timeToExecute: 0
        });
    }

    /**
     * @notice Migrates all database ownership to a new Orchestrator contract
     * @dev Transfers ownership of all databases and any collected fees and remaining balance
     *      to the new orchestrator. Used for contract upgrades.
     * @param orchestratorAddressToMigrate Address of the new Orchestrator contract
     * @param accountToTransferCollectedFees Address to receive the collected platform fees
     */
    function migrateOrchestrator(
        address orchestratorAddressToMigrate,
        address accountToTransferCollectedFees
    ) external onlyOwner {
        if (orchestratorAddressToMigrate == address(0))
            revert ErrorsLib.ProposedAddressCannotBeZero();

        albumDB.transferOwnership(orchestratorAddressToMigrate);
        userDB.transferOwnership(orchestratorAddressToMigrate);
        songDB.transferOwnership(orchestratorAddressToMigrate);
        userDB.transferOwnership(orchestratorAddressToMigrate);

        if (amountCollectedInFees > 0)
            IERC20(stablecoin.current).transfer(
                accountToTransferCollectedFees,
                amountCollectedInFees
            );

        uint256 balance = IERC20(stablecoin.current).balanceOf(address(this));
        IERC20(stablecoin.current).transfer(
            orchestratorAddressToMigrate,
            balance
        );

        newOrchestratorAddress = orchestratorAddressToMigrate;
    }

    /**
     * @notice Withdraws collected platform fees to an external address
     * @dev Only the owner can withdraw fees. Reduces amountCollectedInFees accordingly.
     * @param to Address to receive the withdrawn fees
     * @param amount Amount of fees to withdraw
     */
    function withdrawCollectedFees(
        address to,
        uint256 amount
    ) external onlyOwner {
        if (amountCollectedInFees < amount)
            revert ErrorsLib.InsufficientBalance();
        amountCollectedInFees -= amount;
        IERC20(stablecoin.current).transfer(to, amount);
    }

    /**
     * @notice Distributes collected platform fees to an artist's account balance
     * @dev Only the owner can distribute fees
     * @param artistId The artist ID to receive the fees
     * @param amount Amount of fees to distribute
     */
    function giveCollectedFeesToArtist(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner userIdExists(artistId) {
        if (amountCollectedInFees < amount)
            revert ErrorsLib.InsufficientBalance();

        amountCollectedInFees -= amount;
        userDB.addBalance(artistId, amount);
    }

    /**
     * @notice Distributes collected platform fees to a user's account balance
     * @dev Only the owner can distribute fees
     * @param userId The user ID to receive the fees
     * @param amount Amount of fees to distribute
     */
    function giveCollectedFeesToUser(
        uint256 userId,
        uint256 amount
    ) external onlyOwner userIdExists(userId) {
        if (amountCollectedInFees < amount)
            revert ErrorsLib.InsufficientBalance();

        amountCollectedInFees -= amount;
        userDB.addBalance(userId, amount);
    }

    /**
     * @notice Retrieves the total amount of platform fees collected
     * @dev Only accessible by the owner
     * @return Total fees collected in stablecoin units
     */
    function getAmountCollectedInFees()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return amountCollectedInFees;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Query Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Calculates the total price including platform fees
     * @param netPrice The net price before fees
     * @return totalPrice The total price including fees
     * @return fee The calculated fee amount
     */
    function getPriceWithFee(
        uint256 netPrice
    ) public view returns (uint256 totalPrice, uint256 fee) {
        if (netPrice == 0) return (0, 0);
        fee = (netPrice * uint256(percentageFee)) / 10000;
        return (netPrice + fee, fee);
    }

    /**
     * @notice Gets the current platform fee percentage
     * @return The fee percentage in basis points (100 = 1%, 10000 = 100%)
     */
    function getPercentageFee() external view returns (uint16) {
        return percentageFee;
    }

    /**
     * @notice Gets the current stablecoin address used for payments
     * @return Address of the stablecoin ERC20 token
     */
    function getStablecoinAddress() external view returns (address) {
        return stablecoin.current;
    }

    /**
     * @notice Gets detailed stablecoin information including proposed changes
     * @return AddressProposal struct containing current, proposed, and timelock info
     */
    function getStablecoinInfo()
        external
        view
        returns (StructsLib.AddressProposal memory)
    {
        return stablecoin;
    }

    /**
     * @notice Gets the address of the AlbumDB contract
     * @return Address of the AlbumDB contract
     */
    function getAlbumDBAddress() external view returns (address) {
        return dbAddress.album;
    }

    /**
     * @notice Gets the address of the SongDB contract
     * @return Address of the SongDB contract
     */
    function getSongDBAddress() external view returns (address) {
        return dbAddress.song;
    }

    /**
     * @notice Gets the address of the UserDB contract
     * @return Address of the UserDB contract
     */
    function getUserDBAddress() external view returns (address) {
        return dbAddress.user;
    }

    /**
     * @notice Gets all database contract addresses
     * @return DataBaseList struct containing all four database addresses
     */
    function getDbAddresses()
        external
        view
        returns (StructsLib.DataBaseList memory)
    {
        return dbAddress;
    }

    /**
     * @notice Gets the address of the new orchestrator after migration
     * @return Address of the new Orchestrator contract
     */
    function getNewOrchestratorAddress() external view returns (address) {
        return newOrchestratorAddress;
    }

    /**
     * @notice Gets the current version of the Orchestrator contract
     * @return Version string
     */
    function version() external pure returns (string memory) {
        return '0.0.1 "Koromaru"';
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Internal Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    /**
     * @notice Internal function that processes payments for song/album purchases
     * @dev Handles deduction from user balance, payment to artist, fee collection, and extra amounts (tips).
     *      Reverts if user has insufficient balance for the total amount (price + fee + extra).
     * @param userId The user ID making the purchase
     * @param artistId The artist ID receiving payment
     * @param netPrice The net price (before platform fees)
     * @param extraAmount Optional tip amount going directly to the artist (no fees applied)
     */
    function _executePayment(
        uint256 userId,
        uint256 artistId,
        uint256 netPrice,
        uint256 extraAmount
    ) internal {
        uint256 userBalance = userDB.getBalance(userId);
        (uint256 totalPrice, uint256 calculatedFee) = getPriceWithFee(netPrice);

        uint256 totalToDeduct = totalPrice + extraAmount;
        if (userBalance < totalToDeduct) revert ErrorsLib.InsufficientBalance();

        if (totalToDeduct > 0) {
            userDB.deductBalance(userId, totalToDeduct);
            userDB.addBalance(artistId, netPrice + extraAmount);
        }

        if (calculatedFee > 0) amountCollectedInFees += calculatedFee;
    }
}

/****************************************
You like snooping around code, don't you?
  ⠄⠄⢸⠃⠄⠛⠉⠄⣤⣤⣤⣤⣤⣄⠉⠙⠻⣿⣿⣿⣿⡇⣶⡄⢢⢻⣿⣿⣮⡛   
  ⠄⠄⠘⢀⣠⣾⠄⠘⠋⠉⠉⠛⠻⢿⣦⡲⣄⠈⠻⣿⣇⣣⠹⣯⣄⣦⡙⢿⣿⣿
  ⢀⡎⠄⣾⠋⠄⠄⠄⣠⣤⣤⣤⣤⣄⠈⠙⣍⢳⠄⠘⣿⡐⠁⢉⣁⣀⡀⠄⠙⠿
  ⡼⠄⡆⡇⢀⣤⡆⣿⣿⣿⣿⣿⣿⣿⣷⡘⣿⣷⣄⡀⢹⡇⣾⣿⣿⣿⣿⡇⣄⢠
  ⡇⠄⢿⡔⢿⣿⡇⢿⣿⣿⣿⠿⠿⢿⣿⠇⣿⣿⣿⠇⢈⣁⡻⢿⣿⣀⠈⣱⢏⣾
  ⢣⠄⢆⢩⣮⣿⣿⣄⠻⣿⣷⣤⣤⡴⢋⣴⣿⣿⡟⠄⢸⣿⣿⣷⣶⣶⠾⢫⣪⠅
  ⠘⣆⠈⢑⣘⣿⣿⣿⣷⣶⣤⣤⣴⣾⣿⣿⣿⣿⠃⢀⣿⣿⣿⣿⣿⣿⣿⣿⢇⣴
  ⠄⠘⢦⡈⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢁⣀⣉⣉⣹⣿⣿⣿⣿⠿⡃⠪⣶
  ⠄⠄⠄⠙⠢⢄⡈⠛⠻⠿⠿⠿⠟⠛⠋⣀⠰⣿⣿⣿⣿⡿⠿⡛⠉⡄⠄⠄⠄⣀
  ⠄⠄⠄⠄⢀⡾⢉⣁⠄⠄⠄⠲⠂⢂⠋⠄⠛⠒⠉⠉⠑⠒⠉⠒⠒⡧⠤⠖⢋⣡ <- that's you reading all the code BTW
🮋🮋🮋🮋 Made with ❤️ by 11:11 Labs 🮋🮋🮋🮋  
*****************************************/
