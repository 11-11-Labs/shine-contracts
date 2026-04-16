// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {StructsLib} from "@shine/contracts/orchestrator/library/StructsLib.sol";
import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";

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
        StructsLib.RegisterAlbumInput[]
            memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: true,
            specialEditionName: "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            maxSupplySpecialEdition: 1000,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        vm.stopPrank();

        (AlbumDB.Metadata memory metadata) = albumDB.getMetadata(albumID[0]);

        assertEq(metadata.Title, "Initial Album", "Album title mismatch");
        assertEq(
            metadata.PrincipalArtistId,
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
        StructsLib.RegisterAlbumInput[]
            memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: true,
            specialEditionName: "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            maxSupplySpecialEdition: 1000,
            splitMetadata: new SplitterDB.Metadata[](0)
        });
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        orchestrator.changeAlbumFullData(
            albumID[0],
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

        (AlbumDB.Metadata memory metadata) = albumDB.getMetadata(albumID[0]);

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

        StructsLib.RegisterAlbumInput[]
            memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: true,
            specialEditionName: "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            maxSupplySpecialEdition: 1000,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        orchestrator.changeAlbumPurchaseability(albumID[0], false);
        vm.stopPrank();
        (AlbumDB.Metadata memory metadata) = albumDB.getMetadata(albumID[0]);
        assertFalse(metadata.CanBePurchased, "Album can be purchased mismatch");
    }

    function test_unit_correct_changeAlbumPrice() public {
        vm.startPrank(ARTIST_1.Address);

        StructsLib.RegisterAlbumInput[]
            memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: true,
            specialEditionName: "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            maxSupplySpecialEdition: 1000,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        orchestrator.changeAlbumPrice(albumID[0], 2500);
        vm.stopPrank();
        (AlbumDB.Metadata memory metadata) = albumDB.getMetadata(albumID[0]);
        assertEq(metadata.Price, 2500, "Album price mismatch");
    }

    function test_unit_correct_purchaseAlbum_noExtra() public {
        vm.startPrank(ARTIST_1.Address);
        StructsLib.RegisterAlbumInput[]
            memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: true,
            specialEditionName: "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            maxSupplySpecialEdition: 1000,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        vm.stopPrank();

        (uint256 totalPrice, uint256 fee) = orchestrator.getPriceWithFee(
            albumDB.getMetadata(albumID[0]).Price
        );

        _execute_orchestrator_depositFunds(USER.Address, totalPrice);

        vm.startPrank(USER.Address);
        orchestrator.purchaseAlbum(albumID[0], 0);
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
            albumDB.getMetadata(albumID[0]).Price,
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
        StructsLib.RegisterAlbumInput[]
            memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: true,
            specialEditionName: "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            maxSupplySpecialEdition: 1000,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        vm.stopPrank();

        (uint256 totalPrice, uint256 fee) = orchestrator.getPriceWithFee(
            albumDB.getMetadata(albumID[0]).Price
        );

        uint256 extraAmount = 500;

        _execute_orchestrator_depositFunds(
            USER.Address,
            totalPrice + extraAmount
        );

        vm.startPrank(USER.Address);
        orchestrator.purchaseAlbum(albumID[0], extraAmount);
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
            albumDB.getMetadata(albumID[0]).Price + extraAmount,
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
        StructsLib.RegisterAlbumInput[]
            memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: true,
            specialEditionName: "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            maxSupplySpecialEdition: 1000,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        uint256[] memory albumID = orchestrator.registerAlbum(inputs);

        orchestrator.giftAlbum(albumID[0], USER_ID);
        vm.stopPrank();

        uint256[] memory giftedSongs = userDB.getPurchasedSong(USER_ID);
        assertEq(
            giftedSongs,
            songIDs,
            "User should have received all songs in the gifted album"
        );
    }
}
