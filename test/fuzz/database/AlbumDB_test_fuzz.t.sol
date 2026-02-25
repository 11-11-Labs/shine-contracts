// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";

contract AlbumDB_test_fuzz is Constants {
    function executeBeforeSetUp() internal override {
        albumDB = new AlbumDB(FAKE_ORCHESTRATOR.Address);
    }

    struct RegisterInputs {
        string title;
        uint256 principalUserId;
        string metadataURI;
        uint256[3] musicIds;
        uint256 price;
        bool isPurchasable;
        bool isASpecialEdition;
        string specialEditionName;
        uint256 maxSupplySpecialEdition;
    }

    function test_fuzz_AlbumDB__register(RegisterInputs memory inputs) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.assume(
            inputs.musicIds[0] != inputs.musicIds[1] &&
                inputs.musicIds[0] != inputs.musicIds[2] &&
                inputs.musicIds[1] != inputs.musicIds[2]
        );
        uint256[] memory musicIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            musicIds[i] = inputs.musicIds[i];
        }
        uint256 assignedId = albumDB.register(
            inputs.title,
            inputs.principalUserId,
            inputs.metadataURI,
            musicIds,
            inputs.price,
            inputs.isPurchasable,
            inputs.isASpecialEdition,
            inputs.specialEditionName,
            inputs.maxSupplySpecialEdition
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1");
        assertEq(
            albumDB.getMetadata(assignedId).Title,
            inputs.title,
            "Album title should match"
        );
        assertEq(
            albumDB.getMetadata(assignedId).PrincipalUserId,
            inputs.principalUserId,
            "Principal artist ID should match"
        );
        assertEq(
            albumDB.getMetadata(assignedId).MetadataURI,
            inputs.metadataURI,
            "Metadata URI should match"
        );
        assertEq(
            musicIds,
            albumDB.getMetadata(assignedId).MusicIds,
            "Song IDs should match"
        );
        assertEq(
            albumDB.isPurchasable(assignedId),
            inputs.isPurchasable,
            "Album purchaseability should match"
        );
        assertEq(
            albumDB.getMetadata(assignedId).Price,
            inputs.price,
            "Price should match"
        );
        assertEq(
            albumDB.getMetadata(assignedId).IsASpecialEdition,
            inputs.isASpecialEdition,
            "Special edition status should match"
        );
        assertEq(
            albumDB.getMetadata(assignedId).SpecialEditionName,
            inputs.specialEditionName,
            "Special edition name should match"
        );
        assertEq(
            albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
            inputs.maxSupplySpecialEdition,
            "Max supply for special edition should match"
        );
    }

    function test_fuzz_AlbumDB__purchase(uint256 buyer) public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        uint256[] memory purchasedSongIDs = albumDB.purchase(assignedId, buyer);
        vm.stopPrank();

        assertEq(
            purchasedSongIDs,
            listOfSongIDs,
            "Purchased song IDs should match the registered ones"
        );
        assertEq(
            albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1"
        );
    }

    function test_fuzz_AlbumDB__gift(uint256 receiver) public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        uint256[] memory giftedSongIDs = albumDB.gift(assignedId, receiver);
        vm.stopPrank();

        assertEq(
            giftedSongIDs,
            listOfSongIDs,
            "Gifted song IDs should match the registered ones"
        );
        assertEq(
            albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1"
        );
    }

    function test_fuzz_AlbumDB__purchaseSpecialEdition(uint256 buyer) public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            67
            // he he c:
        );
        uint256[] memory purchasedSongIDs = albumDB.purchase(assignedId, buyer);
        vm.stopPrank();

        assertEq(
            purchasedSongIDs,
            listOfSongIDs,
            "Purchased song IDs should match the registered ones"
        );
        assertEq(
            albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1"
        );
    }

    function test_fuzz_AlbumDB__refund(uint256 user) public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        albumDB.purchase(assignedId, user);
        albumDB.refund(assignedId, user);
        vm.stopPrank();

        assertEq(
            albumDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should be decremented to 0"
        );
    }

    struct ChangeInputs {
        string title;
        uint256 principalUserId;
        string metadataURI;
        uint256[] musicIds;
        uint256 price;
        bool isPurchasable;
        bool isASpecialEdition;
        string specialEditionName;
        uint256 maxSupplySpecialEdition;
    }

    function test_fuzz_AlbumDB__change(ChangeInputs memory inputs) public {
        vm.assume(bytes(inputs.title).length > 0);
        vm.assume(inputs.musicIds.length > 0);
        uint256[] memory listOfSongIDsBefore = new uint256[](3);
        listOfSongIDsBefore[0] = 67;
        listOfSongIDsBefore[1] = 21;
        listOfSongIDsBefore[2] = 420;

        uint256[] memory listOfSongIDsAfter = new uint256[](2);
        listOfSongIDsAfter[0] = 67;
        listOfSongIDsAfter[1] = 21;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDsBefore,
            1000,
            true,
            false,
            "",
            0
        );

        albumDB.change(
            assignedId,
            inputs.title,
            inputs.principalUserId,
            inputs.metadataURI,
            inputs.musicIds,
            inputs.price,
            inputs.isPurchasable,
            inputs.isASpecialEdition,
            inputs.specialEditionName,
            inputs.maxSupplySpecialEdition
        );
        vm.stopPrank();

        assertEq(
            albumDB.getMetadata(assignedId).Title,
            inputs.title,
            "Album title should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).PrincipalUserId,
            inputs.principalUserId,
            "Principal artist ID should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).MetadataURI,
            inputs.metadataURI,
            "Metadata URI should be updated"
        );
        assertEq(
            inputs.musicIds,
            albumDB.getMetadata(assignedId).MusicIds,
            "Song IDs should be updated"
        );
        assertEq(
            albumDB.isPurchasable(assignedId),
            inputs.isPurchasable,
            "Album purchaseability should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).Price,
            inputs.price,
            "Price should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).IsASpecialEdition,
            inputs.isASpecialEdition,
            "Special edition status should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).SpecialEditionName,
            inputs.specialEditionName,
            "Special edition name should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
            inputs.maxSupplySpecialEdition,
            "Max supply for special edition should be updated"
        );
    }

    function test_fuzz_AlbumDB__changePurchaseability(
        bool isPurchasableFlag
    ) public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        albumDB.changePurchaseability(assignedId, isPurchasableFlag);
        vm.stopPrank();
        assertEq(
            albumDB.isPurchasable(assignedId),
            isPurchasableFlag,
            "Album purchaseability should be updated"
        );
    }

    function test_fuzz_AlbumDB__changePrice(uint256 newPrice) public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        albumDB.changePrice(assignedId, newPrice);
        vm.stopPrank();
        assertEq(
            albumDB.getMetadata(assignedId).Price,
            newPrice,
            "Price should be updated"
        );
    }

    function test_fuzz_AlbumDB__setBannedStatus(bool isBanned) public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        albumDB.setBannedStatus(assignedId, isBanned);
        vm.stopPrank();
        assertEq(
            albumDB.getMetadata(assignedId).IsBanned,
            isBanned,
            "Album banned status should be updated"
        );
    }
}
