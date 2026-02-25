// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract SongDB_test_unit_revert is Constants {
    function executeBeforeSetUp() internal override {
        _songDB = new SongDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_revert_SongDB__register__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(1).PrincipalUserId,
            0,
            "Song principalUserId should be 0 as registration failed"
        );
    }

    function test_unit_revert_SongDB__change__Unauthorized() public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        uint256[] memory artistIDsAfter = new uint256[](1);
        artistIDsAfter[0] = 4;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDsBefore,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);

        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.change(
            assignedId,
            "New Song Title",
            2,
            artistIDsAfter,
            "ipfs://newMediaURI",
            "ipfs://newMetadataURI",
            false,
            1000
        );
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).Title,
            "Song Title",
            "Song title should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__change__SongDoesNotExist() public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        uint256[] memory artistIDsAfter = new uint256[](1);
        artistIDsAfter[0] = 4;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.change(
            67,
            "New Song Title",
            2,
            artistIDsAfter,
            "ipfs://newMediaURI",
            "ipfs://newMetadataURI",
            false,
            1000
        );
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(67).Title,
            "",
            "Song title should be unexistent due to revert"
        );
    }

    function test_unit_revert_SongDB__change__SongIsBanned() public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        uint256[] memory artistIDsAfter = new uint256[](1);
        artistIDsAfter[0] = 4;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDsBefore,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        _songDB.change(
            assignedId,
            "New Song Title",
            2,
            artistIDsAfter,
            "ipfs://newMediaURI",
            "ipfs://newMetadataURI",
            false,
            1000
        );
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).Title,
            "Song Title",
            "Song title should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__change__SongNotAssignedToAlbum() public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        uint256[] memory artistIDsAfter = new uint256[](1);
        artistIDsAfter[0] = 4;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDsBefore,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.expectRevert(SongDB.SongNotAssignedToAlbum.selector);
        _songDB.change(
            assignedId,
            "New Song Title",
            2,
            artistIDsAfter,
            "ipfs://newMediaURI",
            "ipfs://newMetadataURI",
            false,
            1000
        );
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).Title,
            "Song Title",
            "Song title should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__SongCannotBePurchased() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            false,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        vm.expectRevert(SongDB.SongCannotBePurchased.selector);
        _songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__SongIsBanned() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        _songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__SongNotAssignedToAlbum() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.expectRevert(SongDB.SongNotAssignedToAlbum.selector);
        _songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__UserAlreadyOwns() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.purchase(assignedId, 10);
        vm.expectRevert(SongDB.UserAlreadyOwns.selector);
        _songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should remain 1 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__SongDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.purchase(42, 10);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(42).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__gift__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.gift(assignedId, 20);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__gift__SongDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.gift(33, 20);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(33).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__gift__SongIsBanned() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        _songDB.gift(assignedId, 20);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__gift__UserAlreadyOwns() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.gift(assignedId, 20);
        vm.expectRevert(SongDB.UserAlreadyOwns.selector);
        _songDB.gift(assignedId, 20);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should remain 1 due to revert"
        );
    }

    function test_unit_revert_SongDB__gift__SongNotAssignedToAlbum() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.expectRevert(SongDB.SongNotAssignedToAlbum.selector);
        _songDB.gift(assignedId, 20);
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__refund__Unauthorised() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.purchase(assignedId, 10);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.refund(assignedId, 10);
        vm.stopPrank();
        assertTrue(
            _songDB.isUserOwner(assignedId, 10),
            "Song should not be marked as bought by user ID 10 after refund"
        );
    }

    function test_unit_revert_SongDB__refund__UserDoesNotOwnSong() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        vm.expectRevert(SongDB.UserDoesNotOwnSong.selector);
        _songDB.refund(assignedId, 10);
        vm.stopPrank();
        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__refund__SongDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.refund(55, 10);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__changePurchaseability__Unauthorized()
        public
    {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
        assertTrue(
            _songDB.getMetadata(assignedId).CanBePurchased,
            "Song purchaseability should be true after revert"
        );
    }

    function test_unit_revert_SongDB__changePurchaseability__SongIsBanned()
        public
    {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        _songDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
        assertTrue(
            _songDB.getMetadata(assignedId).CanBePurchased,
            "Song purchaseability should be true after revert"
        );
    }

    function test_unit_revert_SongDB__changePurchaseability__SongDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.changePurchaseability(88, false);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__changePurchaseability__SongNotAssignedToAlbum()
        public
    {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.expectRevert(SongDB.SongNotAssignedToAlbum.selector);
        _songDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
        assertTrue(
            _songDB.getMetadata(assignedId).CanBePurchased,
            "Song purchaseability should be true after revert"
        );
    }

    function test_unit_revert_SongDB__changePrice__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.changePrice(assignedId, 1000);
        vm.stopPrank();
        assertEq(
            _songDB.getMetadata(assignedId).Price,
            500,
            "Song price should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__changePrice__SongIsBanned() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        _songDB.changePrice(assignedId, 1000);
        vm.stopPrank();
        assertEq(
            _songDB.getMetadata(assignedId).Price,
            500,
            "Song price should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__changePrice__SongNotAssignedToAlbum() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.expectRevert(SongDB.SongNotAssignedToAlbum.selector);
        _songDB.changePrice(assignedId, 1000);
        vm.stopPrank();
        assertEq(
            _songDB.getMetadata(assignedId).Price,
            500,
            "Song price should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__changePrice__SongDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.changePrice(99, 1000);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__setBannedStatus__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.setBannedStatus(assignedId, true);
        vm.stopPrank();
        assertFalse(
            _songDB.getMetadata(assignedId).IsBanned,
            "Song banned status should remain false after revert"
        );
    }

    function test_unit_revert_SongDB__setBannedStatus__SongDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.setBannedStatus(77, true);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__setBannedStatusBatch__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        uint256[] memory songIds = new uint256[](1);
        songIds[0] = assignedId;
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.setBannedStatusBatch(songIds, true);
        vm.stopPrank();
        assertFalse(
            _songDB.getMetadata(assignedId).IsBanned,
            "Song banned status should remain false after revert"
        );
    }

    function test_unit_revert_SongDB__setBannedStatusBatch__SongDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256[] memory songIds = new uint256[](1);
        songIds[0] = 88;
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.setBannedStatusBatch(songIds, false);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__assignToAlbum__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.assignToAlbum(assignedId, 1);
        vm.stopPrank();
    }
    function test_unit_revert_SongDB__assignToAlbum__SongDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.assignToAlbum(1234, 1);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__assignToAlbum__SongIsBanned() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        _songDB.assignToAlbum(assignedId, 1);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__assignToAlbum__AlbumIdCannotBeZero() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.expectRevert(SongDB.AlbumIdCannotBeZero.selector);
        _songDB.assignToAlbum(assignedId, 0);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__assignToAlbumBatch__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        uint256[] memory songIds = new uint256[](1);
        songIds[0] = assignedId;
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.assignToAlbumBatch(songIds, 1);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__assignToAlbumBatch__SongDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256[] memory songIds = new uint256[](1);
        songIds[0] = 99;
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        _songDB.assignToAlbumBatch(songIds, 1);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__assignToAlbumBatch__SongIsBanned()
        public
    {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.setBannedStatus(assignedId, true);
        uint256[] memory songIds = new uint256[](1);
        songIds[0] = assignedId;
        vm.expectRevert(SongDB.SongIsBanned.selector);
        _songDB.assignToAlbumBatch(songIds, 1);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__assignToAlbumBatch__AlbumIdCannotBeZero()
        public
    {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        uint256[] memory songIds = new uint256[](1);
        songIds[0] = assignedId;
        vm.expectRevert(SongDB.AlbumIdCannotBeZero.selector);
        _songDB.assignToAlbumBatch(songIds, 0);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__setListVisibility__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _songDB.setListVisibility(false);
        vm.stopPrank();
    }


}
