// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";
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

        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.UserIdDoesNotExist.selector,
                1000000010000001
            )
        );

        orchestrator.registerSong(
            "Song Title",
            USER_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            1000
        );

        vm.stopPrank();
    }

    function test_unit_revert_registerSong_TitleCannotBeEmpty() public {
        vm.startPrank(ARTIST_1.Address);

        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = ARTIST_2_ID;
        artistIDs[1] = ARTIST_3_ID;

        vm.expectRevert(ErrorsLib.TitleCannotBeEmpty.selector);
        orchestrator.registerSong(
            "",
            USER_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            1000
        );

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


    function test_unit_revert_changeSongPrice_AddressIsNotOwnerOfUserId() public {
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


    
    

    function test_unit_revert_changeSongPurchaseability_AddressIsNotOwnerOfUserId() public {
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

    /*

    function test_unit_revert_purchaseSong_noExtra() public {
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

        (uint256 totalPrice, uint256 calculatedFee) = orchestrator
            .getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(USER_ID, USER.Address, totalPrice);

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

    function test_unit_revert_purchaseSong_extra() public {
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

        (uint256 totalPrice, uint256 calculatedFee) = orchestrator
            .getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(
            USER_ID,
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

    function test_unit_revert_giftSong() public {
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
    */
}
