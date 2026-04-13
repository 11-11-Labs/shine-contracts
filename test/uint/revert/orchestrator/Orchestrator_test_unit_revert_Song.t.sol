// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";
import {StructsLib} from "@shine/contracts/orchestrator/library/StructsLib.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

contract Orchestrator_test_unit_revert_Song is Constants {
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

    function test_unit_revert_registerSong_UserIdDoesNotExist() public {
        vm.startPrank(ARTIST_1.Address);

        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = ARTIST_2_ID;
        artistIDs[1] = 1000000010000001;

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            1
        );
        splitMetadata[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 10000
        });

        StructsLib.RegisterSongInput[]
            memory inputs = new StructsLib.RegisterSongInput[](1);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "Song Title",
            principalArtistId: ARTIST_1_ID,
            artistIDs: artistIDs,
            mediaURI: "https://arweave.net/mediaURI",
            metadataURI: "https://arweave.net/metadataURI",
            canBePurchased: true,
            netprice: 1000,
            splitMetadata: splitMetadata
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.UserIdDoesNotExist.selector,
                1000000010000001
            )
        );

        orchestrator.registerSong(inputs);

        vm.stopPrank();
    }

    function test_unit_revert_registerSong_TitleCannotBeEmpty() public {
        vm.startPrank(ARTIST_1.Address);

        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = ARTIST_2_ID;
        artistIDs[1] = ARTIST_3_ID;

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            1
        );
        splitMetadata[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 10000
        });

        StructsLib.RegisterSongInput[]
            memory inputs = new StructsLib.RegisterSongInput[](1);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "",
            principalArtistId: ARTIST_1_ID,
            artistIDs: artistIDs,
            mediaURI: "https://arweave.net/mediaURI",
            metadataURI: "https://arweave.net/metadataURI",
            canBePurchased: true,
            netprice: 1000,
            splitMetadata: splitMetadata
        });

        vm.expectRevert(ErrorsLib.TitleCannotBeEmpty.selector);
        orchestrator.registerSong(inputs);

        vm.stopPrank();
    }

    function test_unit_revert_registerSong_SplitMetadataUserIdDoesNotExist()
        public
    {
        vm.startPrank(ARTIST_1.Address);

        uint256[] memory artistIDs = new uint256[](0);
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            1
        );
        splitMetadata[0] = SplitterDB.Metadata({
            id: 99999999,
            splitBasisPoints: 10000
        });

        StructsLib.RegisterSongInput[]
            memory inputs = new StructsLib.RegisterSongInput[](1);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "Song With Split",
            principalArtistId: ARTIST_1_ID,
            artistIDs: artistIDs,
            mediaURI: "https://arweave.net/mediaURI",
            metadataURI: "https://arweave.net/metadataURI",
            canBePurchased: true,
            netprice: 1000,
            splitMetadata: splitMetadata
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.UserIdDoesNotExist.selector,
                99999999
            )
        );
        orchestrator.registerSong(inputs);

        vm.stopPrank();
    }

    function test_unit_revert_changeSongFullData_AddressIsNotOwnerOfUserId()
        public
    {
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

        vm.startPrank(ARTIST_2.Address);
        uint256[] memory newArtistIDs = new uint256[](2);
        newArtistIDs[0] = ARTIST_2_ID;
        newArtistIDs[1] = ARTIST_3_ID;
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
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
    }

    function test_unit_revert_changeSongFullData_UserIdDoesNotExist() public {
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

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory newArtistIDs = new uint256[](2);
        newArtistIDs[0] = ARTIST_2_ID;
        newArtistIDs[1] = 77777777777;
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.UserIdDoesNotExist.selector,
                77777777777
            )
        );
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
    }

    function test_unit_revert_changeSongFullData_TitleCannotBeEmpty() public {
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

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory newArtistIDs = new uint256[](2);
        newArtistIDs[0] = ARTIST_2_ID;
        newArtistIDs[1] = ARTIST_3_ID;
        vm.expectRevert(ErrorsLib.TitleCannotBeEmpty.selector);
        orchestrator.changeSongFullData(
            songID,
            "",
            newArtistIDs,
            "https://arweave.net/updatedMediaURI",
            "https://arweave.net/updatedMetadataURI",
            false,
            1500
        );
        vm.stopPrank();
    }

    function test_unit_revert_changeSongPrice_AddressIsNotOwnerOfUserId()
        public
    {
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

        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.changeSongPrice(songID, 2000);
        vm.stopPrank();
    }

    function test_unit_revert_changeSongPurchaseability_AddressIsNotOwnerOfUserId()
        public
    {
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

        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.changeSongPurchaseability(songID, false);
        vm.stopPrank();
    }

    function test_unit_revert_registerSong_AddressIsNotOwnerOfUserId() public {
        vm.startPrank(ARTIST_2.Address);

        uint256[] memory artistIDs = new uint256[](0);

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            1
        );
        splitMetadata[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 10000
        });

        StructsLib.RegisterSongInput[]
            memory inputs = new StructsLib.RegisterSongInput[](1);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "Song Title",
            principalArtistId: ARTIST_1_ID,
            artistIDs: artistIDs,
            mediaURI: "https://arweave.net/mediaURI",
            metadataURI: "https://arweave.net/metadataURI",
            canBePurchased: true,
            netprice: 1000,
            splitMetadata: splitMetadata
        });

        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.registerSong(inputs);

        vm.stopPrank();
    }

    function test_unit_revert_changeSplitOfSong_AddressIsNotOwnerOfUserId()
        public
    {
        uint256[] memory artistIDs = new uint256[](0);

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

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            1
        );
        splitMetadata[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 10000
        });

        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.changeSplitOfSong(songID, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_changeSplitOfSong_UserIdDoesNotExist() public {
        uint256[] memory artistIDs = new uint256[](0);

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

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            2
        );
        splitMetadata[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 5000
        });
        splitMetadata[1] = SplitterDB.Metadata({
            id: 99999999,
            splitBasisPoints: 5000
        });

        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.UserIdDoesNotExist.selector,
                99999999
            )
        );
        orchestrator.changeSplitOfSong(songID, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_changeSplitOfSong_DataIsEmpty() public {
        uint256[] memory artistIDs = new uint256[](0);

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

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            0
        );

        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(SplitterDB.DataIsEmpty.selector);
        orchestrator.changeSplitOfSong(songID, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_changeSplitOfSong_MustSumToMaxBasisPoints()
        public
    {
        uint256[] memory artistIDs = new uint256[](0);

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

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            2
        );
        splitMetadata[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 3000
        });
        splitMetadata[1] = SplitterDB.Metadata({
            id: ARTIST_2_ID,
            splitBasisPoints: 3000
        });

        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(SplitterDB.MustSumToMaxBasisPoints.selector);
        orchestrator.changeSplitOfSong(songID, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_purchaseSong_SongNotAssignedToAlbum() public {
        uint256[] memory artistIDs = new uint256[](0);
        uint256 netPrice = 1000;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Unassigned Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            netPrice
        );

        (uint256 totalPrice, ) = orchestrator.getPriceWithFee(netPrice);
        _execute_orchestrator_depositFunds(USER.Address, totalPrice);

        vm.startPrank(USER.Address);
        vm.expectRevert(SongDB.SongNotAssignedToAlbum.selector);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();
    }

    function test_unit_revert_purchaseSong_SongCannotBePurchased() public {
        uint256[] memory artistIDs = new uint256[](0);
        uint256 netPrice = 1000;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Non-purchasable Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            false,
            netPrice
        );
        _assign_song_to_album_direct(songID, 1);

        (uint256 totalPrice, ) = orchestrator.getPriceWithFee(netPrice);
        _execute_orchestrator_depositFunds(USER.Address, totalPrice);

        vm.startPrank(USER.Address);
        vm.expectRevert(SongDB.SongCannotBePurchased.selector);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();
    }

    function test_unit_revert_purchaseSong_UserAlreadyOwns() public {
        uint256[] memory artistIDs = new uint256[](0);
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

        (uint256 totalPrice, ) = orchestrator.getPriceWithFee(netPrice);
        _execute_orchestrator_depositFunds(USER.Address, totalPrice * 2);

        vm.startPrank(USER.Address);
        orchestrator.purchaseSong(songID, 0);
        vm.expectRevert(SongDB.UserAlreadyOwns.selector);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();
    }

    function test_unit_revert_purchaseSong_InsufficientBalance() public {
        uint256[] memory artistIDs = new uint256[](0);
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

        vm.startPrank(USER.Address);
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();
    }

    function test_unit_revert_giftSong_AddressIsNotOwnerOfUserId() public {
        uint256[] memory artistIDs = new uint256[](0);

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Giftable Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            1000
        );

        vm.startPrank(ARTIST_2.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.giftSong(songID, USER_ID);
        vm.stopPrank();
    }

    function test_unit_revert_giftSong_SongNotAssignedToAlbum() public {
        uint256[] memory artistIDs = new uint256[](0);

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Giftable Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            1000
        );

        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(SongDB.SongNotAssignedToAlbum.selector);
        orchestrator.giftSong(songID, USER_ID);
        vm.stopPrank();
    }

    function test_unit_revert_giftSong_UserAlreadyOwns() public {
        uint256[] memory artistIDs = new uint256[](0);

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Giftable Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            1000
        );
        _assign_song_to_album_direct(songID, 1);

        vm.startPrank(ARTIST_1.Address);
        orchestrator.giftSong(songID, USER_ID);
        vm.expectRevert(SongDB.UserAlreadyOwns.selector);
        orchestrator.giftSong(songID, USER_ID);
        vm.stopPrank();
    }

    function test_unit_revert_registerSong__DataIsEmpty() public {
        vm.startPrank(ARTIST_1.Address);

        StructsLib.RegisterSongInput[]
            memory inputs = new StructsLib.RegisterSongInput[](0);

        vm.expectRevert(ErrorsLib.DataIsEmpty.selector);
        orchestrator.registerSong(inputs);

        vm.stopPrank();
    }

    function test_unit_revert_registerSong__TitleCannotBeEmpty_inBatch()
        public
    {
        uint256[] memory emptyArtists = new uint256[](0);

        SplitterDB.Metadata[] memory splitMetadata0 = new SplitterDB.Metadata[](
            1
        );
        splitMetadata0[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 10000
        });

        SplitterDB.Metadata[] memory splitMetadata1 = new SplitterDB.Metadata[](
            1
        );
        splitMetadata1[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 10000
        });

        StructsLib.RegisterSongInput[]
            memory inputs = new StructsLib.RegisterSongInput[](2);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "Valid Title",
            principalArtistId: ARTIST_1_ID,
            artistIDs: emptyArtists,
            mediaURI: "https://arweave.net/media1URI",
            metadataURI: "https://arweave.net/metadata1URI",
            canBePurchased: true,
            netprice: 1000,
            splitMetadata: splitMetadata0
        });
        inputs[1] = StructsLib.RegisterSongInput({
            title: "",
            principalArtistId: ARTIST_1_ID,
            artistIDs: emptyArtists,
            mediaURI: "https://arweave.net/media2URI",
            metadataURI: "https://arweave.net/metadata2URI",
            canBePurchased: true,
            netprice: 1000,
            splitMetadata: splitMetadata1
        });

        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(ErrorsLib.TitleCannotBeEmpty.selector);
        orchestrator.registerSong(inputs);
        vm.stopPrank();
    }

    function test_unit_revert_registerSong__UserIdDoesNotExist_inBatch()
        public
    {
        uint256[] memory badArtists = new uint256[](1);
        badArtists[0] = 99999999;

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            1
        );
        splitMetadata[0] = SplitterDB.Metadata({
            id: ARTIST_1_ID,
            splitBasisPoints: 10000
        });

        StructsLib.RegisterSongInput[]
            memory inputs = new StructsLib.RegisterSongInput[](1);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "Valid Title",
            principalArtistId: ARTIST_1_ID,
            artistIDs: badArtists,
            mediaURI: "https://arweave.net/mediaURI",
            metadataURI: "https://arweave.net/metadataURI",
            canBePurchased: true,
            netprice: 1000,
            splitMetadata: splitMetadata
        });

        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.UserIdDoesNotExist.selector,
                99999999
            )
        );
        orchestrator.registerSong(inputs);
        vm.stopPrank();
    }
}
