// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";
import {StructsLib} from "@shine/contracts/orchestrator/library/StructsLib.sol";

contract Orchestrator_test_unit_correct_Song is Constants {
    AccountData ARTIST_3 = WILDCARD_ACCOUNT;
    uint256 USER_ID;
    uint256 ARTIST_1_ID;
    uint256 ARTIST_2_ID;
    uint256 ARTIST_3_ID;
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
        ARTIST_3_ID = _execute_orchestrator_register(
            "third_artist",
            "https://arweave.net/thirdArtistURI",
            ARTIST_3.Address
        );
        USER_ID = _execute_orchestrator_register(
            "initial_user",
            "https://arweave.net/initialUserURI",
            USER.Address
        );
    }

    function test_unit_correct_registerSong() public {
        vm.startPrank(ARTIST_1.Address);

        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = ARTIST_2_ID;
        artistIDs[1] = ARTIST_3_ID;

        StructsLib.RegisterSongInput[] memory inputs = new StructsLib.RegisterSongInput[](1);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "Song Title",
            principalArtistId: ARTIST_1_ID,
            artistIDs: artistIDs,
            mediaURI: "https://arweave.net/mediaURI",
            metadataURI: "https://arweave.net/metadataURI",
            canBePurchased: true,
            netprice: 1000
        });

        uint256[] memory songIds = orchestrator.registerSong(inputs);
        uint256 songID = songIds[0];

        vm.stopPrank();

        assertEq(
            songID,
            1,
            "Song ID should be 1 for the first registered song"
        );

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.Title, "Song Title", "Song title should match");
        assertEq(
            song.PrincipalArtistId,
            ARTIST_1_ID,
            "Principal artist ID should match"
        );
        assertEq(song.ArtistIDs, artistIDs, "Artist IDs should match");
        assertEq(
            song.MediaURI,
            "https://arweave.net/mediaURI",
            "Media URI should match"
        );
        assertEq(
            song.MetadataURI,
            "https://arweave.net/metadataURI",
            "Metadata URI should match"
        );
        assertTrue(song.CanBePurchased, "Song should be purchasable");
        assertEq(song.Price, 1000, "Song price should match");
        assertEq(
            song.TimesBought,
            0,
            "Times bought should be initialized to 0"
        );
        assertFalse(song.IsBanned, "Song should not be banned");
    }

    function test_unit_correct_setSplitOfSong() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = ARTIST_2_ID;
        artistIDs[1] = ARTIST_3_ID;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Split Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            1000
        );


        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](3);
        splitMetadata[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 5000
        });
        splitMetadata[1] = SplitterDB.Metadata({
            id: ARTIST_2_ID,
            splitBasisPoints: 3000
        });
        splitMetadata[2] = SplitterDB.Metadata({
            id: ARTIST_3_ID,
            splitBasisPoints: 2000
        });

        vm.startPrank(ARTIST_1.Address);
        orchestrator.setSplitOfSong(songID, splitMetadata);
        vm.stopPrank();

        SplitterDB.Metadata[] memory retrievedSplit = splitterDB.getSplits(
            false,
            songID
        );

        assertEq(
            retrievedSplit.length,
            splitMetadata.length,
            "Retrieved split length should match"
        );

        for (uint256 i; i < splitMetadata.length; ) {
            assertEq(
                retrievedSplit[i].id,
                splitMetadata[i].id,
                "Split recipient ID should match"
            );
            assertEq(
                retrievedSplit[i].splitBasisPoints,
                splitMetadata[i].splitBasisPoints,
                "Split basis points should match"
            );
            unchecked {
                ++i;
            }
        }


    }

    function test_unit_correct_changeSongFullData() public {
        uint256[] memory initialArtistIDs = new uint256[](1);
        initialArtistIDs[0] = ARTIST_2_ID;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            initialArtistIDs,
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );
        _assign_song_to_album_direct(songID, 1);

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory newArtistIDs = new uint256[](2);
        newArtistIDs[0] = ARTIST_2_ID;
        newArtistIDs[1] = ARTIST_3_ID;
        orchestrator.changeSongFullData(
            songID,
            "Updated Song",
            newArtistIDs,
            "https://arweave.net/updatedMediaURI",
            "https://arweave.net/updatedMetadataURI",
            false,
            1500
        );
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.Title, "Updated Song", "Updated song title should match");
        assertEq(
            song.PrincipalArtistId,
            ARTIST_1_ID,
            "Principal artist ID should match"
        );
        assertEq(
            song.ArtistIDs,
            newArtistIDs,
            "Updated artist IDs should match"
        );
        assertEq(
            song.MediaURI,
            "https://arweave.net/updatedMediaURI",
            "Updated media URI should match"
        );
        assertEq(
            song.MetadataURI,
            "https://arweave.net/updatedMetadataURI",
            "Updated metadata URI should match"
        );
        assertFalse(song.CanBePurchased, "Song should not be purchasable");
        assertEq(song.Price, 1500, "Updated song price should match");
        assertEq(song.TimesBought, 0, "Times bought should remain unchanged");
        assertFalse(song.IsBanned, "Song should not be banned");
    }

    function test_unit_correct_changeSongPrice() public {
        uint256[] memory artistIDs = new uint256[](1);
        artistIDs[0] = ARTIST_2_ID;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );
        _assign_song_to_album_direct(songID, 1);

        vm.startPrank(ARTIST_1.Address);
        orchestrator.changeSongPrice(songID, 2000);
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.Price, 2000, "Updated song price should match");
    }

    function test_unit_correct_changeSongPurchaseability() public {
        uint256[] memory artistIDs = new uint256[](1);
        artistIDs[0] = ARTIST_2_ID;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );
        _assign_song_to_album_direct(songID, 1);

        vm.startPrank(ARTIST_1.Address);
        orchestrator.changeSongPurchaseability(songID, false);
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertFalse(song.CanBePurchased, "Song should not be purchasable");
    }

    function test_unit_correct_purchaseSong_noExtra() public {
        uint256[] memory artistIDs = new uint256[](1);
        artistIDs[0] = ARTIST_2_ID;

        uint256 netPrice = 1000;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Purchasable Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            netPrice
        );
        _assign_song_to_album_direct(songID, 1);

        (uint256 totalPrice, uint256 calculatedFee) = orchestrator
            .getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(USER.Address, totalPrice);

        vm.startPrank(USER.Address);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(USER_ID);

        uint256[] memory expectedSongs = new uint256[](1);
        expectedSongs[0] = songID;

        assertEq(
            purchasedSongs,
            expectedSongs,
            "User should have one purchased song"
        );

        assertEq(
            songDB.getMetadata(songID).TimesBought,
            1,
            "Song's times bought should be incremented"
        );

        assertEq(
            userDB.getMetadata(USER_ID).Balance,
            0,
            "User's balance should be zero after purchase"
        );

        assertEq(
            userDB.getMetadata(ARTIST_1_ID).Balance,
            netPrice,
            "Principal artist's balance should be updated"
        );

        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            feesCollected,
            calculatedFee,
            "Platform fees collected should match the calculated fee"
        );
    }

    function test_unit_correct_purchaseSong_extra() public {
        uint256[] memory artistIDs = new uint256[](1);
        artistIDs[0] = ARTIST_2_ID;

        uint256 netPrice = 1000;
        uint256 extraAmount = 500;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Purchasable Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            netPrice
        );
        _assign_song_to_album_direct(songID, 1);

        (uint256 totalPrice, uint256 calculatedFee) = orchestrator
            .getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(
            USER.Address,
            totalPrice + extraAmount
        );

        vm.startPrank(USER.Address);
        orchestrator.purchaseSong(songID, extraAmount);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB.getPurchasedSong(USER_ID);

        uint256[] memory expectedSongs = new uint256[](1);
        expectedSongs[0] = songID;

        assertEq(
            purchasedSongs,
            expectedSongs,
            "User should have one purchased song"
        );

        assertEq(
            songDB.getMetadata(songID).TimesBought,
            1,
            "Song's times bought should be incremented"
        );

        assertEq(
            userDB.getMetadata(USER_ID).Balance,
            0,
            "User's balance should be zero after purchase"
        );

        assertEq(
            userDB.getMetadata(ARTIST_1_ID).Balance,
            netPrice + extraAmount,
            "Principal artist's balance should be updated"
        );

        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            feesCollected,
            calculatedFee,
            "Platform fees collected should match the calculated fee"
        );
    }

    function test_unit_correct_giftSong() public {
        uint256[] memory artistIDs = new uint256[](1);
        artistIDs[0] = ARTIST_2_ID;

        uint256 netPrice = 1000;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Giftable Song",
            ARTIST_1_ID,
            artistIDs,
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

        assertEq(
            giftedSongs,
            expectedSongs,
            "Recipient should have the gifted song"
        );

        assertEq(
            songDB.getMetadata(songID).TimesBought,
            1,
            "Song's times bought should be incremented"
        );

        assertEq(
            userDB.getMetadata(USER_ID).Balance,
            0,
            "Gifter's balance should be unchanged after gifting"
        );

        assertEq(
            userDB.getMetadata(ARTIST_1_ID).Balance,
            0,
            "Principal artist's balance should be unchanged after gifting"
        );
    }

    function test_unit_correct_registerSongOnBatch() public {
        uint256[] memory artistIDs0 = new uint256[](1);
        artistIDs0[0] = ARTIST_2_ID;
        uint256[] memory artistIDs1 = new uint256[](0);

        StructsLib.RegisterSongInput[] memory inputs = new StructsLib.RegisterSongInput[](2);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "Batch Song One",
            principalArtistId: ARTIST_1_ID,
            artistIDs: artistIDs0,
            mediaURI: "https://arweave.net/batch1MediaURI",
            metadataURI: "https://arweave.net/batch1MetadataURI",
            canBePurchased: true,
            netprice: 1000
        });
        inputs[1] = StructsLib.RegisterSongInput({
            title: "Batch Song Two",
            principalArtistId: ARTIST_1_ID,
            artistIDs: artistIDs1,
            mediaURI: "https://arweave.net/batch2MediaURI",
            metadataURI: "https://arweave.net/batch2MetadataURI",
            canBePurchased: false,
            netprice: 2000
        });

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory songIds = orchestrator.registerSong(inputs);
        vm.stopPrank();

        assertEq(songIds.length, 2, "Should return 2 song IDs");

        SongDB.Metadata memory song0 = songDB.getMetadata(songIds[0]);
        assertEq(song0.Title, "Batch Song One", "First song title should match");
        assertEq(song0.PrincipalArtistId, ARTIST_1_ID, "First song principal artist should match");
        assertTrue(song0.CanBePurchased, "First song should be purchasable");
        assertEq(song0.Price, 1000, "First song price should match");

        SongDB.Metadata memory song1 = songDB.getMetadata(songIds[1]);
        assertEq(song1.Title, "Batch Song Two", "Second song title should match");
        assertEq(song1.PrincipalArtistId, ARTIST_1_ID, "Second song principal artist should match");
        assertFalse(song1.CanBePurchased, "Second song should not be purchasable");
        assertEq(song1.Price, 2000, "Second song price should match");
    }

    function test_unit_correct_setSplitOfSongs() public {
        uint256 songID1 = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Split Batch Song One",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/split1MediaURI",
            "https://arweave.net/split1MetadataURI",
            true,
            1000
        );

        uint256 songID2 = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Split Batch Song Two",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/split2MediaURI",
            "https://arweave.net/split2MetadataURI",
            true,
            2000
        );

        uint256[] memory songIds = new uint256[](2);
        songIds[0] = songID1;
        songIds[1] = songID2;

        SplitterDB.Metadata[][] memory allSplits = new SplitterDB.Metadata[][](2);

        allSplits[0] = new SplitterDB.Metadata[](2);
        allSplits[0][0] = SplitterDB.Metadata({id: ARTIST_1_ID, splitBasisPoints: 7000});
        allSplits[0][1] = SplitterDB.Metadata({id: ARTIST_2_ID, splitBasisPoints: 3000});

        allSplits[1] = new SplitterDB.Metadata[](2);
        allSplits[1][0] = SplitterDB.Metadata({id: ARTIST_1_ID, splitBasisPoints: 5000});
        allSplits[1][1] = SplitterDB.Metadata({id: ARTIST_3_ID, splitBasisPoints: 5000});

        vm.startPrank(ARTIST_1.Address);
        orchestrator.setSplitOfSongs(songIds, allSplits);
        vm.stopPrank();

        SplitterDB.Metadata[] memory split0 = splitterDB.getSplits(false, songID1);
        assertEq(split0.length, 2, "Song 1 split length should be 2");
        assertEq(split0[0].id, ARTIST_1_ID, "Song 1 split[0] id should match");
        assertEq(split0[0].splitBasisPoints, 7000, "Song 1 split[0] basis points should match");
        assertEq(split0[1].id, ARTIST_2_ID, "Song 1 split[1] id should match");
        assertEq(split0[1].splitBasisPoints, 3000, "Song 1 split[1] basis points should match");

        SplitterDB.Metadata[] memory split1 = splitterDB.getSplits(false, songID2);
        assertEq(split1.length, 2, "Song 2 split length should be 2");
        assertEq(split1[0].id, ARTIST_1_ID, "Song 2 split[0] id should match");
        assertEq(split1[0].splitBasisPoints, 5000, "Song 2 split[0] basis points should match");
        assertEq(split1[1].id, ARTIST_3_ID, "Song 2 split[1] id should match");
        assertEq(split1[1].splitBasisPoints, 5000, "Song 2 split[1] basis points should match");
    }
}
