// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {UserDB} from "@shine/contracts/database/UserDB.sol";

contract UserDB_test_unit_correct is Constants {
    function executeBeforeSetUp() internal override {
        _userDB = new UserDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_correct_UserDB__register() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1 for the first user");
        assertEq(
            _userDB.getMetadata(assignedId).Username,
            "User Name",
            "Username should match the registered name"
        );
        assertEq(
            _userDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should match the registered URI"
        );
        assertEq(
            _userDB.getMetadata(assignedId).Address,
            USER.Address,
            "User address should match the registered address"
        );
        assertEq(
            _userDB.getMetadata(assignedId).PurchasedSongIds.length,
            0,
            "Purchased song IDs should be initialized to an empty array"
        );
        assertEq(
            _userDB.getMetadata(assignedId).Balance,
            0,
            "Balance should be initialized to 0"
        );
    }

    function test_unit_correct_UserDB__changeBasicData() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.changeBasicData(
            assignedId,
            "New User Name",
            "ipfs://newMetadataURI"
        );
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).Username,
            "New User Name",
            "Username should be updated correctly"
        );
        assertEq(
            _userDB.getMetadata(assignedId).MetadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated correctly"
        );
    }

    function test_unit_correct_UserDB__changeAddress() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).Address,
            address(67),
            "User address should be updated correctly"
        );
        assertEq(
            _userDB.getId(address(67)),
            assignedId,
            "Address to ID mapping should be updated correctly"
        );
        assertEq(
            _userDB.getId(USER.Address),
            0,
            "Old address should no longer map to any user ID"
        );
    }

    function test_unit_correct_UserDB__addSong() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addSong(assignedId, 101);
        vm.stopPrank();

        uint256[] memory purchasedSongs = _userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songs,
            "Purchased song IDs array should have one entry"
        );
    }

    function test_unit_correct_UserDB__deleteSong() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        uint256[] memory songsAfter = new uint256[](9);
        songsAfter[0] = 100;
        songsAfter[1] = 101;
        songsAfter[2] = 102;
        songsAfter[3] = 103;
        songsAfter[4] = 105;
        songsAfter[5] = 106;
        songsAfter[6] = 107;
        songsAfter[7] = 108;
        songsAfter[8] = 109;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addSongs(assignedId, songsBefore);
        _userDB.deleteSong(assignedId, 104);
        vm.stopPrank();

        uint256[] memory purchasedSongs = _userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsAfter,
            "Purchased song IDs array should have the correct entries after removal"
        );
    }

    function test_unit_correct_UserDB__addSongs() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addSongs(assignedId, songsBefore);
        vm.stopPrank();

        uint256[] memory purchasedSongs = _userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsBefore,
            "Purchased song IDs array should have all added entries"
        );
    }

    function test_unit_correct_UserDB__deleteSongs() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        uint256[] memory songsAfter = new uint256[](8);
        songsAfter[0] = 100;
        songsAfter[1] = 101;
        songsAfter[2] = 102;
        songsAfter[3] = 103;
        //songToDelete  104;
        songsAfter[4] = 105;
        songsAfter[5] = 106;
        songsAfter[6] = 107;
        //songToDelete  108;
        songsAfter[7] = 109;

        uint256[] memory songsToDelete = new uint256[](2);
        songsToDelete[0] = 104;
        songsToDelete[1] = 108;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addSongs(assignedId, songsBefore);
        _userDB.deleteSongs(assignedId, songsToDelete);
        vm.stopPrank();

        uint256[] memory purchasedSongs = _userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsAfter,
            "Purchased song IDs array should have the correct entries after removal"
        );
    }

    function test_unit_correct_UserDB__addBalance() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addBalance(assignedId, 100);
        vm.stopPrank();

        assertEq(
            _userDB.getBalance(assignedId),
            100,
            "Balance should be updated correctly"
        );
    }

    function test_unit_correct_UserDB__deductBalance() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addBalance(assignedId, 100);
        _userDB.deductBalance(assignedId, 50);
        vm.stopPrank();

        assertEq(
            _userDB.getBalance(assignedId),
            50,
            "Balance should be updated correctly"
        );
    }

    function test_unit_correct_UserDB__setBannedStatus() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.setBannedStatus(assignedId, true);
        vm.stopPrank();

        assertTrue(
            _userDB.getMetadata(assignedId).IsBanned,
            "User should be marked as banned"
        );
    }


    function test_unit_correct_UserDB__addAccumulatedRoyalties() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        _userDB.addAccumulatedRoyalties(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).AccumulatedRoyalties,
            1000,
            "Accumulated royalties should be updated correctly"
        );
    }

    function test_unit_correct_UserDB__deductAccumulatedRoyalties() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        _userDB.addAccumulatedRoyalties(assignedId, 1000);
        _userDB.deductAccumulatedRoyalties(assignedId, 500);
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).AccumulatedRoyalties,
            500,
            "Accumulated royalties should be updated correctly"
        );
    }
}
