// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {StructsLib} from "@shine/contracts/orchestrator/library/StructsLib.sol";
import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";

contract Orchestrator_test_fuzz_Album is Constants {
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

    struct RegisterAlbumFuzzInput {
        string title;
        string metadataURI;
        uint112 price;
        bool canBePurchased;
    }

    function test_fuzz_registerAlbum(RegisterAlbumFuzzInput memory input) public {
        vm.assume(bytes(input.title).length > 0);

        StructsLib.RegisterAlbumInput[] memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: input.title,
            principalArtistId: ARTIST_ID,
            metadataURI: input.metadataURI,
            songIDs: songIDs,
            price: input.price,
            canBePurchased: input.canBePurchased,
            isASpecialEdition: false,
            specialEditionName: "",
            maxSupplySpecialEdition: 0,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        vm.stopPrank();

        AlbumDB.Metadata memory metadata = albumDB.getMetadata(albumID[0]);
        assertEq(metadata.Title, input.title, "Album title should match");
        assertEq(metadata.PrincipalArtistId, ARTIST_ID, "Album principal artist ID should match");
        assertEq(metadata.MetadataURI, input.metadataURI, "Album metadata URI should match");
        assertEq(metadata.MusicIds, songIDs, "Album song IDs should match");
        assertEq(metadata.Price, input.price, "Album price should match");
        assertEq(metadata.TimesBought, 0, "Album times bought should be initialized to 0");
        assertEq(metadata.CanBePurchased, input.canBePurchased, "Album purchasability should match");
        assertFalse(metadata.IsASpecialEdition, "Album should not be a special edition");
    }

    struct ChangeAlbumFullDataInput {
        string updatedTitle;
        string updatedMetadataURI;
        uint112 updatedPrice;
        bool updatedCanBePurchased;
    }

    function test_fuzz_changeAlbumFullData(ChangeAlbumFullDataInput memory input) public {
        vm.assume(bytes(input.updatedTitle).length > 0);

        vm.startPrank(ARTIST_1.Address);
        StructsLib.RegisterAlbumInput[] memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: false,
            specialEditionName: "",
            maxSupplySpecialEdition: 0,
            splitMetadata: new SplitterDB.Metadata[](0)
        });
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        orchestrator.changeAlbumFullData(
            albumID[0],
            input.updatedTitle,
            ARTIST_ID,
            input.updatedMetadataURI,
            songIDs,
            input.updatedPrice,
            input.updatedCanBePurchased,
            "",
            0
        );
        vm.stopPrank();

        AlbumDB.Metadata memory metadata = albumDB.getMetadata(albumID[0]);
        assertEq(metadata.Title, input.updatedTitle, "Updated album title should match");
        assertEq(metadata.MetadataURI, input.updatedMetadataURI, "Updated album metadata URI should match");
        assertEq(metadata.Price, input.updatedPrice, "Updated album price should match");
        assertEq(metadata.CanBePurchased, input.updatedCanBePurchased, "Updated purchasability should match");
        assertEq(metadata.MusicIds, songIDs, "Album song IDs should remain unchanged");
    }

    function test_fuzz_changeAlbumPrice(uint112 newPrice) public {
        vm.startPrank(ARTIST_1.Address);
        StructsLib.RegisterAlbumInput[] memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: false,
            specialEditionName: "",
            maxSupplySpecialEdition: 0,
            splitMetadata: new SplitterDB.Metadata[](0)
        });
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        orchestrator.changeAlbumPrice(albumID[0], newPrice);
        vm.stopPrank();

        AlbumDB.Metadata memory metadata = albumDB.getMetadata(albumID[0]);
        assertEq(metadata.Price, newPrice, "Updated album price should match");
    }

    function test_fuzz_changeAlbumPurchaseability(bool canBePurchased) public {
        vm.startPrank(ARTIST_1.Address);
        StructsLib.RegisterAlbumInput[] memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: 1500,
            canBePurchased: true,
            isASpecialEdition: false,
            specialEditionName: "",
            maxSupplySpecialEdition: 0,
            splitMetadata: new SplitterDB.Metadata[](0)
        });
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        orchestrator.changeAlbumPurchaseability(albumID[0], canBePurchased);
        vm.stopPrank();

        AlbumDB.Metadata memory metadata = albumDB.getMetadata(albumID[0]);
        assertEq(metadata.CanBePurchased, canBePurchased, "Updated purchasability should match");
    }

    function test_fuzz_purchaseAlbum_noExtra(uint112 netPrice) public {
        vm.startPrank(ARTIST_1.Address);
        StructsLib.RegisterAlbumInput[] memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: netPrice,
            canBePurchased: true,
            isASpecialEdition: false,
            specialEditionName: "",
            maxSupplySpecialEdition: 0,
            splitMetadata: new SplitterDB.Metadata[](0)
        });
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        vm.stopPrank();

        (uint256 totalPrice, uint256 fee) = orchestrator.getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(USER.Address, totalPrice);

        vm.startPrank(USER.Address);
        orchestrator.purchaseAlbum(albumID[0], 0);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(USER_ID);
        assertEq(purchasedSongs, songIDs, "User should have purchased all songs in the album");
        assertEq(userDB.getMetadata(USER_ID).Balance, 0, "User's balance should be zero after purchase");
        assertEq(
            userDB.getMetadata(ARTIST_ID).Balance,
            netPrice,
            "Principal artist's balance should be updated"
        );

        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(feesCollected, fee, "Platform fees collected should match the calculated fee");
    }

    function test_fuzz_purchaseAlbum_extra(uint112 netPrice, uint112 extraAmount) public {
        vm.startPrank(ARTIST_1.Address);
        StructsLib.RegisterAlbumInput[] memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Initial Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: netPrice,
            canBePurchased: true,
            isASpecialEdition: false,
            specialEditionName: "",
            maxSupplySpecialEdition: 0,
            splitMetadata: new SplitterDB.Metadata[](0)
        });
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        vm.stopPrank();

        (uint256 totalPrice, uint256 fee) = orchestrator.getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(USER.Address, totalPrice + uint256(extraAmount));

        vm.startPrank(USER.Address);
        orchestrator.purchaseAlbum(albumID[0], extraAmount);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(USER_ID);
        assertEq(purchasedSongs, songIDs, "User should have purchased all songs in the album");
        assertEq(userDB.getMetadata(USER_ID).Balance, 0, "User's balance should be zero after purchase");
        assertEq(
            userDB.getMetadata(ARTIST_ID).Balance,
            uint256(netPrice) + uint256(extraAmount),
            "Principal artist's balance should include the extra amount"
        );

        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(feesCollected, fee, "Platform fees collected should match the calculated fee");
    }

    function test_fuzz_giftAlbum(uint112 netPrice) public {
        vm.startPrank(ARTIST_1.Address);
        StructsLib.RegisterAlbumInput[] memory inputs = new StructsLib.RegisterAlbumInput[](1);
        inputs[0] = StructsLib.RegisterAlbumInput({
            title: "Giftable Album",
            principalArtistId: ARTIST_ID,
            metadataURI: "https://arweave.net/initialAlbumMetadataURI",
            songIDs: songIDs,
            price: netPrice,
            canBePurchased: true,
            isASpecialEdition: false,
            specialEditionName: "",
            maxSupplySpecialEdition: 0,
            splitMetadata: new SplitterDB.Metadata[](0)
        });
        uint256[] memory albumID = orchestrator.registerAlbum(inputs);
        orchestrator.giftAlbum(albumID[0], USER_ID);
        vm.stopPrank();

        uint256[] memory giftedSongs = userDB.getPurchasedSong(USER_ID);
        assertEq(giftedSongs, songIDs, "User should have received all songs in the gifted album");
        assertEq(userDB.getMetadata(USER_ID).Balance, 0, "Recipient balance should remain zero");
        assertEq(userDB.getMetadata(ARTIST_ID).Balance, 0, "Artist balance should remain unchanged");
    }
}
