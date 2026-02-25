// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {UserDB} from "@shine/contracts/database/UserDB.sol";

contract Orchestrator_test_unit_correct_UserArtist is Constants {
    function test_unit_correct_register_user() public {
        vm.startPrank(USER.Address);
        uint256 userId = orchestrator.register(
            "awesome_user67",
            "https://arweave.net/N_XzB9pQ8L2v4M1wT0r7jK5qS4tZ3sD2yL9v8X0m1A7",
            USER.Address
        );
        vm.stopPrank();

        UserDB.Metadata memory user = userDB.getMetadata(userId);

        assertEq(user.Username, "awesome_user67", "Username should match");
        assertEq(
            user.MetadataURI,
            "https://arweave.net/N_XzB9pQ8L2v4M1wT0r7jK5qS4tZ3sD2yL9v8X0m1A7",
            "User metadata URI should match"
        );
        assertEq(user.Address, USER.Address, "User address should match");
        assertEq(user.Balance, 0, "User balance should be zero");
        assertEq(
            user.PurchasedSongIds,
            new uint256[](0),
            "User should have no purchased songs"
        );
        assertFalse(user.IsBanned, "User should not be banned");
    }

    function test_unit_correct_register_artist() public {
        vm.startPrank(ARTIST_1.Address);
        uint256 artistId = orchestrator.register(
            "cool_artist99",
            "https://arweave.net/Vp_3kL9mR6v4N0zB1x8jS2qT5wZ7sC4yM0v9X1n2A8",
            ARTIST_1.Address
        );
        vm.stopPrank();

        UserDB.Metadata memory artist = userDB.getMetadata(artistId);

        assertEq(artist.Username, "cool_artist99", "Username should match");
        assertEq(
            artist.MetadataURI,
            "https://arweave.net/Vp_3kL9mR6v4N0zB1x8jS2qT5wZ7sC4yM0v9X1n2A8",
            "Artist metadata URI should match"
        );
        assertEq(
            artist.Address,
            ARTIST_1.Address,
            "Artist address should match"
        );
        assertEq(artist.Balance, 0, "Artist balance should be zero");
        assertEq(
            artist.AccumulatedRoyalties,
            0,
            "Artist accumulated royalties should be zero"
        );
        assertFalse(artist.IsBanned, "Artist should not be banned");
    }

    function test_unit_correct_chnageBasicData_artist() public {
        uint256 artistId = _execute_orchestrator_register(
            "initial_artist",
            "https://arweave.net/initialURI",
            ARTIST_1.Address
        );

        vm.startPrank(ARTIST_1.Address);
        orchestrator.chnageBasicData(
            artistId,
            "updated_artist",
            "https://arweave.net/updatedURI"
        );
        vm.stopPrank();

        UserDB.Metadata memory artist = userDB.getMetadata(artistId);

        assertEq(
            artist.Username,
            "updated_artist",
            "Updated name should match"
        );
        assertEq(
            artist.MetadataURI,
            "https://arweave.net/updatedURI",
            "Updated metadata URI should match"
        );
    }

    function test_unit_correct_chnageBasicData_user() public {
        uint256 userId = _execute_orchestrator_register(
            "initial_user",
            "https://arweave.net/initialUserURI",
            USER.Address
        );

        vm.startPrank(USER.Address);
        orchestrator.chnageBasicData(
            userId,
            "updated_user",
            "https://arweave.net/updatedUserURI"
        );
        vm.stopPrank();

        UserDB.Metadata memory user = userDB.getMetadata(userId);

        assertEq(
            user.Username,
            "updated_user",
            "Updated username should match"
        );
        assertEq(
            user.MetadataURI,
            "https://arweave.net/updatedUserURI",
            "Updated metadata URI should match"
        );
    }

    function test_unit_correct_changeAddress_artist() public {
        uint256 artistId = _execute_orchestrator_register(
            "artist_name",
            "https://arweave.net/artistURI",
            ARTIST_1.Address
        );

        vm.startPrank(ARTIST_1.Address);
        orchestrator.changeAddress(artistId, WILDCARD_ACCOUNT.Address);
        vm.stopPrank();

        UserDB.Metadata memory artist = userDB.getMetadata(artistId);

        assertEq(
            artist.Address,
            WILDCARD_ACCOUNT.Address,
            "Updated address should match"
        );
        assertEq(
            userDB.getId(WILDCARD_ACCOUNT.Address),
            artistId,
            "New address should map to correct artist ID"
        );
        assertEq(
            userDB.getId(ARTIST_1.Address),
            0,
            "Old address should no longer map to any artist ID"
        );
    }

    function test_unit_correct_changeAddress_user() public {
        uint256 userId = _execute_orchestrator_register(
            "user_name",
            "https://arweave.net/userURI",
            USER.Address
        );

        vm.startPrank(USER.Address);
        orchestrator.changeAddress(userId, WILDCARD_ACCOUNT.Address);
        vm.stopPrank();

        UserDB.Metadata memory user = userDB.getMetadata(userId);

        assertEq(
            user.Address,
            WILDCARD_ACCOUNT.Address,
            "Updated address should match"
        );
        assertEq(
            userDB.getId(WILDCARD_ACCOUNT.Address),
            userId,
            "New address should map to correct user ID"
        );
        assertEq(
            userDB.getId(USER.Address),
            0,
            "Old address should no longer map to any user ID"
        );
    }
}
