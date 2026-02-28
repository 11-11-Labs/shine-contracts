// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract AlbumDB_test_unit_revert is Constants {
    function executeBeforeSetUp() internal override {
        _albumDB = new AlbumDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_revert_AlbumDB__register__Unauthorized() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(USER.Address);

        vm.expectRevert(Ownable.Unauthorized.selector);
        uint256 assignedId = _albumDB.register(
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
        vm.stopPrank();

        assertEq(assignedId, 0, "Assigned ID should be zero due to revert");
    }

    function test_unit_revert_AlbumDB__register__SongAlreadyUsedInAlbum()
        public
    {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _albumDB.register(
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

        vm.expectRevert(
            abi.encodeWithSelector(AlbumDB.SongAlreadyUsedInAlbum.selector, 67)
        );
        uint256 assignedId2 = _albumDB.register(
            "Another Album Title",
            2,
            "ipfs://anotherMetadataURI",
            listOfSongIDs,
            1500,
            true,
            false,
            "",
            0
        );
        vm.stopPrank();

        assertEq(assignedId2, 0, "Assigned ID should be zero due to revert");
    }
    function test_unit_revert_AlbumDB__purchase__Unauthorized() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        vm.stopPrank();

        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _albumDB.purchase(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_AlbumDB__purchase__AlbumIsBanned() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.setBannedStatus(assignedId, true);
        vm.expectRevert(AlbumDB.AlbumIsBanned.selector);
        _albumDB.purchase(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_AlbumDB__purchase__AlbumDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(AlbumDB.AlbumDoesNotExist.selector);
        _albumDB.purchase(9999, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(9999).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_AlbumDB__purchase__UserAlreadyOwns() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.purchase(assignedId, 1234);
        vm.expectRevert(AlbumDB.UserAlreadyOwns.selector);
        _albumDB.purchase(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be 1 after first purchase"
        );
    }

    function test_unit_revert_AlbumDB__purchase__AlbumNotPurchasable() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            false,
            false,
            "",
            0
        );
        vm.expectRevert(AlbumDB.AlbumNotPurchasable.selector);
        _albumDB.purchase(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_AlbumDB__purchaseSpecialEdition__AlbumMaxSupplyReached()
        public
    {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            // he he c:
            1
        );
        _albumDB.purchase(assignedId, 1234);
        vm.expectRevert(AlbumDB.AlbumMaxSupplyReached.selector);
        _albumDB.purchase(assignedId, 5678);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should remain 1 due to revert"
        );
    }

    function test_unit_revert_AlbumDB__gift__Unauthorized() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _albumDB.gift(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should be 0 because of revert"
        );
    }

    function test_unit_revert_AlbumDB__gift__AlbunDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(AlbumDB.AlbumDoesNotExist.selector);
        _albumDB.gift(9999, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(9999).TimesBought,
            0,
            "Times bought should be 0 because of revert"
        );
    }

    function test_unit_revert_AlbumDB__gift__AlbumIsBanned() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.setBannedStatus(assignedId, true);

        vm.expectRevert(AlbumDB.AlbumIsBanned.selector);
        _albumDB.gift(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should be 0 because of revert"
        );
    }

    function test_unit_revert_AlbumDB__gift__UserAlreadyOwns() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.gift(assignedId, 1234);
        vm.expectRevert(AlbumDB.UserAlreadyOwns.selector);
        _albumDB.gift(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be 1 because of first gift"
        );
    }

    function test_unit_revert_AlbumDB__gift__AlbumMaxSupplyReached() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            // he he c:
            1
        );
        _albumDB.gift(assignedId, 1234);
        vm.expectRevert(AlbumDB.AlbumMaxSupplyReached.selector);
        _albumDB.gift(assignedId, 5678);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be 1 because of first gift"
        );
    }

    function test_unit_revert_AlbumDB__refund__Unauthorised() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.purchase(assignedId, 1234);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _albumDB.refund(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be 1 because of revert"
        );
    }

    function test_unit_revert_AlbumDB__refund__AlbunDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(AlbumDB.AlbumDoesNotExist.selector);
        _albumDB.refund(9999, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(9999).TimesBought,
            0,
            "Times bought should be 0 because of revert"
        );
    }

    function test_unit_revert_AlbumDB__refund__UserNotOwnedAlbum() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        vm.expectRevert(AlbumDB.UserNotOwnedAlbum.selector);
        _albumDB.refund(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should be 0 because of revert"
        );
    }

    function test_unit_revert_AlbumDB__change__Unauthorized() public {
        uint256[] memory listOfSongIDsBefore = new uint256[](3);
        listOfSongIDsBefore[0] = 67;
        listOfSongIDsBefore[1] = 21;
        listOfSongIDsBefore[2] = 420;

        uint256[] memory listOfSongIDsAfter = new uint256[](2);
        listOfSongIDsAfter[0] = 67;
        listOfSongIDsAfter[1] = 21;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _albumDB.change(
            assignedId,
            "New Album Title",
            2,
            "ipfs://newMetadataURI",
            listOfSongIDsAfter,
            2000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            67
        );
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).Title,
            "Album Title",
            "Title should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).PrincipalArtistId,
            1,
            "PrincipalArtistId should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "MetadataURI should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MusicIds.length,
            3,
            "MusicIds length should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).Price,
            1000,
            "Price should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).IsASpecialEdition,
            false,
            "IsASpecialEdition should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).SpecialEditionName,
            "",
            "SpecialEditionName should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
            0,
            "MaxSupplySpecialEdition should be the same due to revert"
        );
    }

    function test_unit_revert_AlbumDB__change__SongAlreadyUsedInAlbum()
        public
    {
        uint256[] memory listOfSongIDs1 = new uint256[](2);
        listOfSongIDs1[0] = 1;
        listOfSongIDs1[1] = 2;

        uint256[] memory listOfSongIDs2 = new uint256[](2);
        listOfSongIDs2[0] = 3;
        listOfSongIDs2[1] = 4;

        uint256[] memory listOfSongIDsAfter = new uint256[](2);
        listOfSongIDsAfter[0] = 3;
        listOfSongIDsAfter[1] = 21;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId1 = _albumDB.register(
            "Album One",
            1,
            "ipfs://metadataURI1",
            listOfSongIDs1,
            1000,
            true,
            false,
            "",
            0
        );

        uint256 assignedId2 = _albumDB.register(
            "Album Two",
            2,
            "ipfs://metadataURI2",
            listOfSongIDs2,
            1500,
            true,
            false,
            "",
            0
        );

        vm.expectRevert(
            abi.encodeWithSelector(AlbumDB.SongAlreadyUsedInAlbum.selector, 3)
        );
        _albumDB.change(
            assignedId1,
            "New Album Title",
            2,
            "ipfs://newMetadataURI",
            listOfSongIDsAfter,
            2000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            67
        );
        vm.stopPrank();
    }

    function test_unit_revert_AlbumDB__change__AlbumIsBanned() public {
        uint256[] memory listOfSongIDsBefore = new uint256[](3);
        listOfSongIDsBefore[0] = 67;
        listOfSongIDsBefore[1] = 21;
        listOfSongIDsBefore[2] = 420;

        uint256[] memory listOfSongIDsAfter = new uint256[](2);
        listOfSongIDsAfter[0] = 67;
        listOfSongIDsAfter[1] = 21;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.setBannedStatus(assignedId, true);

        vm.expectRevert(AlbumDB.AlbumIsBanned.selector);
        _albumDB.change(
            assignedId,
            "New Album Title",
            2,
            "ipfs://newMetadataURI",
            listOfSongIDsAfter,
            2000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            67
        );
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).Title,
            "Album Title",
            "Title should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).PrincipalArtistId,
            1,
            "PrincipalArtistId should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "MetadataURI should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MusicIds.length,
            3,
            "MusicIds length should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).Price,
            1000,
            "Price should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).IsASpecialEdition,
            false,
            "IsASpecialEdition should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).SpecialEditionName,
            "",
            "SpecialEditionName should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
            0,
            "MaxSupplySpecialEdition should be the same due to revert"
        );
    }

    function test_unit_revert_AlbumDB__change__AlbumDoesNotExist() public {
        uint256[] memory listOfSongIDsAfter = new uint256[](2);
        listOfSongIDsAfter[0] = 67;
        listOfSongIDsAfter[1] = 21;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(AlbumDB.AlbumDoesNotExist.selector);
        _albumDB.change(
            9999,
            "New Album Title",
            2,
            "ipfs://newMetadataURI",
            listOfSongIDsAfter,
            2000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            67
        );
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(9999).MaxSupplySpecialEdition,
            0,
            "MaxSupplySpecialEdition should be 0 due to revert"
        );
    }

    function test_unit_revert_AlbumDB__change__AlbumCannotHaveZeroSongs()
        public
    {
        uint256[] memory listOfSongIDsBefore = new uint256[](3);
        listOfSongIDsBefore[0] = 67;
        listOfSongIDsBefore[1] = 21;
        listOfSongIDsBefore[2] = 420;

        uint256[] memory listOfSongIDsAfter = new uint256[](0);

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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

        vm.expectRevert(AlbumDB.AlbumCannotHaveZeroSongs.selector);
        _albumDB.change(
            assignedId,
            "New Album Title",
            2,
            "ipfs://newMetadataURI",
            listOfSongIDsAfter,
            2000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            67
        );
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).Title,
            "Album Title",
            "Title should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).PrincipalArtistId,
            1,
            "PrincipalArtistId should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "MetadataURI should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MusicIds.length,
            3,
            "MusicIds length should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).Price,
            1000,
            "Price should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).IsASpecialEdition,
            false,
            "IsASpecialEdition should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).SpecialEditionName,
            "",
            "SpecialEditionName should be the same due to revert"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
            0,
            "MaxSupplySpecialEdition should be the same due to revert"
        );
    }

    function test_unit_revert_AlbumDB__changePurchaseability__Unauthorized()
        public
    {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _albumDB.changePurchaseability(assignedId, false);
        vm.stopPrank();

        assertTrue(
            _albumDB.isPurchasable(assignedId),
            "Album should remain purchasable due to revert"
        );
    }

    function test_unit_revert_AlbumDB__changePurchaseability__AlbumIsBanned()
        public
    {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.setBannedStatus(assignedId, true);

        vm.expectRevert(AlbumDB.AlbumIsBanned.selector);
        _albumDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
    }

    function test_unit_revert_AlbumDB__changePurchaseability__AlbumDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(AlbumDB.AlbumDoesNotExist.selector);
        _albumDB.changePurchaseability(9999, false);
        vm.stopPrank();
    }

    function test_unit_revert_AlbumDB__changePrice__Unauthorized() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _albumDB.changePrice(assignedId, 67);
        vm.stopPrank();
        assertEq(
            _albumDB.getMetadata(assignedId).Price,
            1000,
            "Price should be the same due to revert"
        );
    }

    function test_unit_revert_AlbumDB__changePrice__AlbumIsBanned() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.setBannedStatus(assignedId, true);
        vm.expectRevert(AlbumDB.AlbumIsBanned.selector);
        _albumDB.changePrice(assignedId, 67);
        vm.stopPrank();
        assertEq(
            _albumDB.getMetadata(assignedId).Price,
            1000,
            "Price should be the same due to revert"
        );
    }

    function test_unit_revert_AlbumDB__changePrice__AlbumDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(AlbumDB.AlbumDoesNotExist.selector);
        _albumDB.changePrice(9999, 67);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(9999).Price,
            0,
            "Price should be 0 due to revert"
        );
    }

    function test_unit_correct_AlbumDB__setBannedStatus__Unauthorized() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _albumDB.setBannedStatus(assignedId, true);
        vm.stopPrank();
        assertFalse(
            _albumDB.getMetadata(assignedId).IsBanned,
            "Album should remain unbanned due to revert"
        );
    }

    function test_unit_correct_AlbumDB__setBannedStatus__AlbumDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(AlbumDB.AlbumDoesNotExist.selector);
        _albumDB.setBannedStatus(9999, true);
        vm.stopPrank();

        assertFalse(
            _albumDB.getMetadata(9999).IsBanned,
            "Album should remain unbanned due to revert"
        );
    }

    function test_unit_correct_AlbumDB__setListVisibility__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _albumDB.setListVisibility( true);
        vm.stopPrank();
    }
}
