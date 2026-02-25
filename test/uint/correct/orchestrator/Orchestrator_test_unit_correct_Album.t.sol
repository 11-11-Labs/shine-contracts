// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";

contract Orchestrator_test_unit_correct_Album is Constants {
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

    function test_unit_correct_registerAlbum() public {
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

        (AlbumDB.Metadata memory metadata) = albumDB.getMetadata(albumID);

        assertEq(metadata.Title, "Initial Album", "Album title mismatch");
        assertEq(
            metadata.PrincipalUserId,
            ARTIST_ID,
            "Album principal artist ID mismatch"
        );
        assertEq(
            metadata.MetadataURI,
            "https://arweave.net/initialAlbumMetadataURI",
            "Album metadata URI mismatch"
        );
        assertEq(metadata.MusicIds, songIDs, "Album song IDs mismatch");
        assertEq(metadata.Price, 1500, "Album price mismatch");
        assertEq(metadata.TimesBought, 0, "Album times bought mismatch");
        assertTrue(metadata.CanBePurchased, "Album can be purchased mismatch");
        assertTrue(
            metadata.IsASpecialEdition,
            "Album is a special edition mismatch"
        );
        assertEq(
            metadata.SpecialEditionName,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            "Album special edition name mismatch"
        );
        assertEq(
            metadata.MaxSupplySpecialEdition,
            1000,
            "Album max supply special edition mismatch"
        );
    }

    function test_unit_correct_changeAlbumFullData() public {
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
        orchestrator.changeAlbumFullData(
            albumID,
            "Updated Album Title",
            ARTIST_ID,
            "https://arweave.net/updatedAlbumMetadataURI",
            songIDs,
            2000,
            false,
            "Updated Special Edition Name",
            2000
        );
        vm.stopPrank();

        (AlbumDB.Metadata memory metadata) = albumDB.getMetadata(albumID);

        assertEq(metadata.Title, "Updated Album Title", "Album title mismatch");
        assertEq(
            metadata.MetadataURI,
            "https://arweave.net/updatedAlbumMetadataURI",
            "Album metadata URI mismatch"
        );
        assertEq(metadata.MusicIds, songIDs, "Album song IDs mismatch");
        assertEq(metadata.Price, 2000, "Album price mismatch");
        assertFalse(metadata.CanBePurchased, "Album can be purchased mismatch");
        assertTrue(
            metadata.IsASpecialEdition,
            "Album is a special edition mismatch"
        );
        assertEq(
            metadata.SpecialEditionName,
            "Updated Special Edition Name",
            "Album special edition name mismatch"
        );
        assertEq(
            metadata.MaxSupplySpecialEdition,
            2000,
            "Album max supply special edition mismatch"
        );
    }

    function test_unit_correct_changeAlbumPurchaseability() public {
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
        orchestrator.changeAlbumPurchaseability(albumID, false);
        vm.stopPrank();
        (AlbumDB.Metadata memory metadata) = albumDB.getMetadata(albumID);
        assertFalse(metadata.CanBePurchased, "Album can be purchased mismatch");
    }

    function test_unit_correct_changeAlbumPrice() public {
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
        orchestrator.changeAlbumPrice(albumID, 2500);
        vm.stopPrank();
        (AlbumDB.Metadata memory metadata) = albumDB.getMetadata(albumID);
        assertEq(metadata.Price, 2500, "Album price mismatch");
    }

    function test_unit_correct_purchaseAlbum_noExtra() public {
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

        (uint256 totalPrice, uint256 fee) = orchestrator.getPriceWithFee(
            albumDB.getMetadata(albumID).Price
        );

        _execute_orchestrator_depositFunds(USER_ID, USER.Address, totalPrice);

        vm.startPrank(USER.Address);
        orchestrator.purchaseAlbum(albumID,0);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(USER_ID);

        
        assertEq(
            purchasedSongs,
            songIDs,
            "User should have purchased all songs in the album"
        );

        assertEq(
            userDB.getMetadata(USER_ID).Balance,
            0,
            "User's balance should be zero after purchase"
        );

        assertEq(
            userDB.getMetadata(ARTIST_ID).Balance,
            albumDB.getMetadata(albumID).Price,
            "Principal artist's balance should be updated"
        );

        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            feesCollected,
            fee,
            "Platform fees collected should match the calculated fee"
        );

    }

    function test_unit_correct_purchaseAlbum_extra() public {
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

        (uint256 totalPrice, uint256 fee) = orchestrator.getPriceWithFee(
            albumDB.getMetadata(albumID).Price
        );
        
        uint256 extraAmount = 500;

        _execute_orchestrator_depositFunds(
            USER_ID,
            USER.Address,
            totalPrice + extraAmount
        );

        vm.startPrank(USER.Address);
        orchestrator.purchaseAlbum(albumID,extraAmount);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(USER_ID);

        
        assertEq(
            purchasedSongs,
            songIDs,
            "User should have purchased all songs in the album"
        );

        assertEq(
            userDB.getMetadata(USER_ID).Balance,
            0,
            "User's balance should reflect the extra amount after purchase"
        );

        assertEq(
            userDB.getMetadata(ARTIST_ID).Balance,
            albumDB.getMetadata(albumID).Price + extraAmount,
            "Principal artist's balance should be updated"
        );

        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            feesCollected,
            fee,
            "Platform fees collected should match the calculated fee"
        );
    }


    function test_unit_correct_giftAlbum() public {
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
        
        orchestrator.giftAlbum(albumID, USER_ID);
        vm.stopPrank();

        uint256[] memory giftedSongs = userDB.getPurchasedSong(USER_ID);
        assertEq(
            giftedSongs,
            songIDs,
            "User should have received all songs in the gifted album"
        );
        
    }

}
