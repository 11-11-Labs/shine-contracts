// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";

contract Orchestrator_test_unit_revert_Album is Constants {
    AccountData ARTIST_3 = WILDCARD_ACCOUNT;
    uint256 USER_ID;
    uint256 ARTIST_ID;

    uint[] songIDs = new uint[](3);

    function executeBeforeSetUp() internal override {
        ARTIST_ID = _execute_orchestrator_register(
            "initial_artist",
            "https://arweave.net/initialArtistURI",
            ARTIST_1.Address
        );
        _execute_orchestrator_register(
            "initial_artist",
            "https://arweave.net/initialArtistURI",
            ARTIST_2.Address
        );
        USER_ID = _execute_orchestrator_register(
            "initial_user",
            "https://arweave.net/initialUserURI",
            USER.Address
        );

        songIDs[0] = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_ID,
            new uint256[](0),
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );

        songIDs[1] = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Second Song",
            ARTIST_ID,
            new uint256[](0),
            "https://arweave.net/secondMediaURI",
            "https://arweave.net/secondMetadataURI",
            true,
            700
        );

        songIDs[2] = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Third Song",
            ARTIST_ID,
            new uint256[](0),
            "https://arweave.net/thirdMediaURI",
            "https://arweave.net/thirdMetadataURI",
            true,
            600
        );
    }

    function test_unit_revert_registerAlbum__TitleCannotBeEmpty() public {
        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(ErrorsLib.TitleCannotBeEmpty.selector);
        uint256 albumID = orchestrator.registerAlbum(
            "",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();
    }

    function test_unit_revert_registerAlbum__AddressIsNotOwnerOfUserId()
        public
    {
        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();
    }

    function test_unit_revert_registerAlbum__MaxSupplyMustBeGreaterThanZero()
        public
    {
        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(ErrorsLib.MaxSupplyMustBeGreaterThanZero.selector);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            0
        );
        vm.stopPrank();
    }

    function test_unit_revert_registerAlbum__SpecialEditionNameCannotBeEmpty()
        public
    {
        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(ErrorsLib.SpecialEditionNameCannotBeEmpty.selector);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "",
            1000
        );
        vm.stopPrank();
    }

    function test_unit_revert_registerAlbum__SongIdDoesNotExist() public {
        vm.startPrank(ARTIST_1.Address);
        uint256[] memory invalidSongIDs = new uint256[](1);
        invalidSongIDs[0] = 9999; // Assuming this song ID does not exist
        vm.expectRevert(
            abi.encodeWithSelector(ErrorsLib.SongIdDoesNotExist.selector, 9999)
        );
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            invalidSongIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();
    }

    function test_unit_revert_registerAlbum__ListCannotContainSongsFromDifferentPrincipalArtist()
        public
    {
        uint256[] memory invalidSongIDs = new uint256[](1);
        invalidSongIDs[0] = _execute_orchestrator_registerSong(
            ARTIST_2.Address,
            "Initial Song",
            2,
            new uint256[](0),
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );
        vm.startPrank(ARTIST_1.Address);

        vm.expectRevert(
            ErrorsLib
                .ListCannotContainSongsFromDifferentPrincipalArtist
                .selector
        );

        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            invalidSongIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();
    }

    function test_unit_revert_changeAlbumFullData__MustBeGreaterThanCurrent()
        public
    {
        vm.startPrank(ARTIST_1.Address);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );

        // Gift to USER_ID so TimesBought becomes 1
        orchestrator.giftAlbum(albumID, USER_ID);

        // maxSupplySpecialEdition = 1 <= TimesBought (1), so it should revert
        vm.expectRevert(ErrorsLib.MustBeGreaterThanCurrent.selector);
        orchestrator.changeAlbumFullData(
            albumID,
            "Updated Album Title",
            ARTIST_ID,
            "https://arweave.net/updatedAlbumMetadataURI",
            songIDs,
            2000,
            true,
            "Updated Special Edition Name",
            1
        );
        vm.stopPrank();
    }

    function test_unit_revert_changeAlbumFullData__AddressIsNotOwnerOfUserId()
        public
    {
        vm.startPrank(ARTIST_1.Address);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();
        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.changeAlbumFullData(
            albumID,
            "Updated Album Title",
            ARTIST_ID,
            "https://arweave.net/updatedAlbumMetadataURI",
            songIDs,
            2000,
            true,
            "Updated Special Edition Name",
            1
        );
        vm.stopPrank();
    }

    function test_unit_revert_changeAlbumPurchaseability__AddressIsNotOwnerOfUserId()
        public
    {
        vm.startPrank(ARTIST_1.Address);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();
        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.changeAlbumPurchaseability(albumID, false);
        vm.stopPrank();
    }

    function test_unit_revert_changeAlbumPrice__AddressIsNotOwnerOfUserId()
        public
    {
        vm.startPrank(ARTIST_1.Address);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();
        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.changeAlbumPrice(albumID, 2500);
        vm.stopPrank();
    }

    function test_unit_revert_purchaseAlbum_noExtra__InsufficientBalance()
        public
    {
        vm.startPrank(ARTIST_1.Address);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();

        vm.startPrank(USER.Address);
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.purchaseAlbum(albumID, 0);
        vm.stopPrank();
    }

    function test_unit_revert_purchaseAlbum_extra__InsufficientBalance()
        public
    {
        vm.startPrank(ARTIST_1.Address);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();

        uint256 extraAmount = 500;

        vm.startPrank(USER.Address);
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.purchaseAlbum(albumID, extraAmount);
        vm.stopPrank();
    }

    function test_unit_revert_giftAlbum__AddressIsNotOwnerOfUserId() public {
        vm.startPrank(ARTIST_1.Address);
        uint256 albumID = orchestrator.registerAlbum(
            "Initial Album",
            ARTIST_ID,
            "https://arweave.net/initialAlbumMetadataURI",
            songIDs,
            1500,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            1000
        );
        vm.stopPrank();
        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.giftAlbum(albumID, USER_ID);
        vm.stopPrank();
    }
}
