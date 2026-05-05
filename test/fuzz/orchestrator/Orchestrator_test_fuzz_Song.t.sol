// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";
import {StructsLib} from "@shine/contracts/orchestrator/library/StructsLib.sol";

contract Orchestrator_test_fuzz_Song is Constants {
    uint256 USER_ID;
    uint256 ARTIST_1_ID;
    uint256 ARTIST_2_ID;

    function executeBeforeSetUp() internal override {
        ARTIST_1_ID = _execute_orchestrator_register(
            "initial_artist",
            "https://arweave.net/initialArtistURI",
            ARTIST_1.Address
        );
        ARTIST_2_ID = _execute_orchestrator_register(
            "second_artist",
            "https://arweave.net/secondArtistURI",
            ARTIST_2.Address
        );
        USER_ID = _execute_orchestrator_register(
            "initial_user",
            "https://arweave.net/initialUserURI",
            USER.Address
        );
    }

    struct RegisterSongFuzzInput {
        string title;
        string mediaURI;
        string metadataURI;
        bool canBePurchased;
        uint112 netprice;
    }

    function test_fuzz_registerSong(RegisterSongFuzzInput memory input) public {
        vm.assume(bytes(input.title).length > 0);

        StructsLib.RegisterSongInput[] memory inputs = new StructsLib.RegisterSongInput[](1);
        inputs[0] = StructsLib.RegisterSongInput({
            title: input.title,
            principalArtistId: ARTIST_1_ID,
            artistIDs: new uint256[](0),
            mediaURI: input.mediaURI,
            metadataURI: input.metadataURI,
            canBePurchased: input.canBePurchased,
            netprice: input.netprice,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory songIds = orchestrator.registerSong(inputs);
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songIds[0]);
        assertEq(song.Title, input.title, "Song title should match");
        assertEq(song.PrincipalArtistId, ARTIST_1_ID, "Principal artist ID should match");
        assertEq(song.MediaURI, input.mediaURI, "Media URI should match");
        assertEq(song.MetadataURI, input.metadataURI, "Metadata URI should match");
        assertEq(song.CanBePurchased, input.canBePurchased, "Purchasability should match");
        assertEq(song.Price, input.netprice, "Song price should match");
        assertEq(song.TimesBought, 0, "Times bought should be initialized to 0");
        assertFalse(song.IsBanned, "Song should not be banned");
    }

    struct ChangeSongFullDataInput {
        string updatedTitle;
        string updatedMediaURI;
        string updatedMetadataURI;
        bool updatedCanBePurchased;
        uint112 updatedPrice;
    }

    function test_fuzz_changeSongFullData(ChangeSongFullDataInput memory input) public {
        vm.assume(bytes(input.updatedTitle).length > 0);

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );
        _assign_song_to_album_direct(songID, 1);

        vm.startPrank(ARTIST_1.Address);
        orchestrator.changeSongFullData(
            songID,
            input.updatedTitle,
            new uint256[](0),
            input.updatedMediaURI,
            input.updatedMetadataURI,
            input.updatedCanBePurchased,
            input.updatedPrice
        );
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.Title, input.updatedTitle, "Updated song title should match");
        assertEq(song.MediaURI, input.updatedMediaURI, "Updated media URI should match");
        assertEq(song.MetadataURI, input.updatedMetadataURI, "Updated metadata URI should match");
        assertEq(song.CanBePurchased, input.updatedCanBePurchased, "Updated purchasability should match");
        assertEq(song.Price, input.updatedPrice, "Updated song price should match");
        assertEq(song.TimesBought, 0, "Times bought should remain unchanged");
        assertFalse(song.IsBanned, "Song should not be banned");
    }

    function test_fuzz_changeSongPrice(uint112 newPrice) public {
        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );
        _assign_song_to_album_direct(songID, 1);

        vm.startPrank(ARTIST_1.Address);
        orchestrator.changeSongPrice(songID, newPrice);
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.Price, newPrice, "Updated song price should match");
    }

    function test_fuzz_changeSongPurchaseability(bool canBePurchased) public {
        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );
        _assign_song_to_album_direct(songID, 1);

        vm.startPrank(ARTIST_1.Address);
        orchestrator.changeSongPurchaseability(songID, canBePurchased);
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.CanBePurchased, canBePurchased, "Updated purchasability should match");
    }

    function test_fuzz_purchaseSong_noExtra(uint112 netPrice) public {
        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Purchasable Song",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            netPrice
        );
        _assign_song_to_album_direct(songID, 1);

        (uint256 totalPrice, uint256 calculatedFee) = orchestrator.getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(USER.Address, totalPrice);

        vm.startPrank(USER.Address);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(USER_ID);
        uint256[] memory expectedSongs = new uint256[](1);
        expectedSongs[0] = songID;

        assertEq(purchasedSongs, expectedSongs, "User should have one purchased song");
        assertEq(songDB.getMetadata(songID).TimesBought, 1, "Song's times bought should be incremented");
        assertEq(userDB.getMetadata(USER_ID).Balance, 0, "User's balance should be zero after purchase");
        assertEq(userDB.getMetadata(ARTIST_1_ID).Balance, netPrice, "Principal artist's balance should be updated");

        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(feesCollected, calculatedFee, "Platform fees collected should match the calculated fee");
    }

    function test_fuzz_purchaseSong_extra(uint112 netPrice, uint112 extraAmount) public {
        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Purchasable Song",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            netPrice
        );
        _assign_song_to_album_direct(songID, 1);

        (uint256 totalPrice, uint256 calculatedFee) = orchestrator.getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(USER.Address, totalPrice + uint256(extraAmount));

        vm.startPrank(USER.Address);
        orchestrator.purchaseSong(songID, extraAmount);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(USER_ID);
        uint256[] memory expectedSongs = new uint256[](1);
        expectedSongs[0] = songID;

        assertEq(purchasedSongs, expectedSongs, "User should have one purchased song");
        assertEq(songDB.getMetadata(songID).TimesBought, 1, "Song's times bought should be incremented");
        assertEq(userDB.getMetadata(USER_ID).Balance, 0, "User's balance should be zero after purchase");
        assertEq(
            userDB.getMetadata(ARTIST_1_ID).Balance,
            uint256(netPrice) + uint256(extraAmount),
            "Principal artist's balance should include the extra amount"
        );

        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(feesCollected, calculatedFee, "Platform fees collected should match the calculated fee");
    }

    function test_fuzz_giftSong(uint112 netPrice) public {
        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Giftable Song",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            netPrice
        );
        _assign_song_to_album_direct(songID, 1);

        vm.startPrank(ARTIST_1.Address);
        orchestrator.giftSong(songID, USER_ID);
        vm.stopPrank();

        uint256[] memory giftedSongs = userDB.getPurchasedSong(USER_ID);
        uint256[] memory expectedSongs = new uint256[](1);
        expectedSongs[0] = songID;

        assertEq(giftedSongs, expectedSongs, "Recipient should have the gifted song");
        assertEq(songDB.getMetadata(songID).TimesBought, 1, "Song's times bought should be incremented");
        assertEq(userDB.getMetadata(USER_ID).Balance, 0, "Recipient balance should remain zero");
        assertEq(userDB.getMetadata(ARTIST_1_ID).Balance, 0, "Principal artist's balance should be unchanged after gifting");
    }
}
