// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {UserDB} from "@shine/contracts/database/UserDB.sol";

contract UserDB_test_fuzz is Constants {
    function executeBeforeSetUp() internal override {
        userDB = new UserDB(FAKE_ORCHESTRATOR.Address);
    }

    struct UserDataInputs {
        string username;
        string metadataURI;
        address userAddress;
    }

    function test_fuzz_UserDB__register(UserDataInputs memory inputs) public {
        vm.assume(bytes(inputs.username).length > 0);
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            inputs.username,
            inputs.metadataURI,
            inputs.userAddress
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1 for the first user");
        assertEq(
            userDB.getMetadata(assignedId).Username,
            inputs.username,
            "Username should match the registered name"
        );
        assertEq(
            userDB.getMetadata(assignedId).MetadataURI,
            inputs.metadataURI,
            "Metadata URI should match the registered URI"
        );
        assertEq(
            userDB.getMetadata(assignedId).Address,
            inputs.userAddress,
            "User address should match the registered address"
        );
        assertEq(
            userDB.getMetadata(assignedId).PurchasedSongIds.length,
            0,
            "Purchased song IDs should be initialized to an empty array"
        );
        assertEq(
            userDB.getMetadata(assignedId).Balance,
            0,
            "Balance should be initialized to 0"
        );
    }

    struct ChangeBasicDataInputs {
        string newName;
        string newMetadataURI;
    }

    function test_fuzz_UserDB__changeBasicData(
        ChangeBasicDataInputs memory inputs
    ) public {
        vm.assume(bytes(inputs.newName).length > 0);
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.changeBasicData(
            assignedId,
            inputs.newName,
            inputs.newMetadataURI
        );
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).Username,
            inputs.newName,
            "Username should be updated correctly"
        );
        assertEq(
            userDB.getMetadata(assignedId).MetadataURI,
            inputs.newMetadataURI,
            "Metadata URI should be updated correctly"
        );
    }

    function test_fuzz_UserDB__changeAddress(address newAddress) public {
        vm.assume(newAddress != address(0) && newAddress != USER.Address);

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.changeAddress(assignedId, newAddress);
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).Address,
            newAddress,
            "User address should be updated correctly"
        );
        assertEq(
            userDB.getId(newAddress),
            assignedId,
            "Address to ID mapping should be updated correctly"
        );
        assertEq(
            userDB.getId(USER.Address),
            0,
            "Old address should no longer map to any user ID"
        );
    }

    function test_fuzz_UserDB__addSong(uint256 songId) public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = songId;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addSong(assignedId, songId);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songs,
            "Purchased song IDs array should have one entry"
        );
    }

    function test_fuzz_UserDB__deleteSong(uint8 songIndex) public {
        songIndex = uint8(bound(songIndex, 100, 109)); // Ensure songIndex is between 100 and 109
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addSongs(assignedId, songsBefore);
        userDB.deleteSong(assignedId, songIndex);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(assignedId);

        bool flagFailed = false;
        for (uint256 i = 0; i < purchasedSongs.length; i++) {
            if (purchasedSongs[i] == songIndex) flagFailed = true;
        }

        assertFalse(
            flagFailed,
            "Purchased song IDs array should not contain the deleted song"
        );
    }

    function test_fuzz_UserDB__addSongs(uint256[15] memory songsToAdd) public {

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        uint256[] memory songs = new uint256[](15);
        for (uint256 i = 0; i < 15; i++) {
            songs[i] = songsToAdd[i];
        }
        userDB.addSongs(assignedId, songs);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songs,
            "Purchased song IDs array should have all added entries"
        );
    }

    function test_fuzz_UserDB__deleteSongs(
        uint8 numSongs,
        uint8 numToDelete,
        uint256 seed
    ) public {
        // Bound the number of songs to add (between 2 and 20)
        numSongs = uint8(bound(numSongs, 2, 20));
        // Bound the number of songs to delete (between 1 and numSongs - 1)
        numToDelete = uint8(bound(numToDelete, 1, numSongs - 1));

        // Create songs array with unique IDs based on seed
        uint256[] memory songsBefore = new uint256[](numSongs);
        for (uint256 i = 0; i < numSongs; i++) {
            songsBefore[i] = uint256(keccak256(abi.encodePacked(seed, i)));
        }

        // Select random indices to delete (using a simple selection method)
        uint256[] memory indicesToDelete = new uint256[](numToDelete);
        bool[] memory isDeleted = new bool[](numSongs);
        
        uint256 deletedCount = 0;
        uint256 iteration = 0;
        while (deletedCount < numToDelete) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, "delete", iteration))) % numSongs;
            if (!isDeleted[randomIndex]) {
                indicesToDelete[deletedCount] = randomIndex;
                isDeleted[randomIndex] = true;
                deletedCount++;
            }
            iteration++;
        }

        // Create the array of song IDs to delete
        uint256[] memory songsToDelete = new uint256[](numToDelete);
        for (uint256 i = 0; i < numToDelete; i++) {
            songsToDelete[i] = songsBefore[indicesToDelete[i]];
        }

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addSongs(assignedId, songsBefore);
        userDB.deleteSongs(assignedId, songsToDelete);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(assignedId);

        // Verify the length is correct
        assertEq(
            purchasedSongs.length,
            numSongs - numToDelete,
            "Purchased songs array should have correct length after deletion"
        );

        // Verify no deleted songs are present
        for (uint256 i = 0; i < purchasedSongs.length; i++) {
            for (uint256 j = 0; j < songsToDelete.length; j++) {
                assertTrue(
                    purchasedSongs[i] != songsToDelete[j],
                    "Deleted song should not be in purchased songs"
                );
            }
        }

        // Verify all non-deleted songs are still present
        for (uint256 i = 0; i < numSongs; i++) {
            if (!isDeleted[i]) {
                bool found = false;
                for (uint256 j = 0; j < purchasedSongs.length; j++) {
                    if (purchasedSongs[j] == songsBefore[i]) {
                        found = true;
                        break;
                    }
                }
                assertTrue(found, "Non-deleted song should still be in purchased songs");
            }
        }
    }

    function test_fuzz_UserDB__addBalance(uint256 amount) public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addBalance(assignedId, amount);
        vm.stopPrank();

        assertEq(
            userDB.getBalance(assignedId),
            amount,
            "Balance should be updated correctly"
        );
    }

    function test_fuzz_UserDB__deductBalance(uint256 initialAmount, uint256 deductAmount) public {
        vm.assume(deductAmount <= initialAmount);

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addBalance(assignedId, initialAmount);
        userDB.deductBalance(assignedId, deductAmount);
        vm.stopPrank();

        assertEq(
            userDB.getBalance(assignedId),
            initialAmount - deductAmount,
            "Balance should be updated correctly"
        );
    }

    function test_fuzz_UserDB__setBannedStatus(bool bannedStatus) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.setBannedStatus(assignedId, bannedStatus);
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).IsBanned,
            bannedStatus,
            "Banned status should be updated correctly"
        );
    }

        function test_fuzz_UserDB__addAccumulatedRoyalties(uint256 amount) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        userDB.addAccumulatedRoyalties(assignedId, amount);
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).AccumulatedRoyalties,
            amount,
            "Accumulated royalties should be updated correctly"
        );
    }

    function test_fuzz_UserDB__deductAccumulatedRoyalties(uint256 amount, uint256 deductAmount) public {
        vm.assume(deductAmount <= amount);
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        userDB.addAccumulatedRoyalties(assignedId, amount);
        userDB.deductAccumulatedRoyalties(assignedId, deductAmount);
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).AccumulatedRoyalties,
            amount - deductAmount,
            "Accumulated royalties should be updated correctly"
        );
    }

}
