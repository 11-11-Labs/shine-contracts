// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";

contract Orchestrator_test_unit_correct_Administrative is Constants {
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

        USER_ID = _execute_orchestrator_register(
            "initial_user",
            "https://arweave.net/initialUserURI",
            USER.Address
        );

        uint256 netPrice = 1000_000000;

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

        (uint256 totalPrice, ) = orchestrator.getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(USER.Address, totalPrice);

        vm.startPrank(USER.Address);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();
    }

    /// @dev setDatabaseAddresses is skipped because
    // it is covered in depth in integration tests

    function test_unit_correct_changePercentageFee() public {
        vm.startPrank(ADMIN.Address);
        orchestrator.changePercentageFee(500); // 5%
        vm.stopPrank();

        assertEq(
            orchestrator.getPercentageFee(),
            500,
            "Percentage fee should be updated to 500 basis points"
        );
    }

    function test_unit_correct_proposeStablecoinAddressChange() public {
        vm.startPrank(ADMIN.Address);
        orchestrator.proposeStablecoinAddressChange(address(6767));
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().current,
            address(usdc),
            "Current stablecoin address should remain unchanged"
        );

        assertEq(
            orchestrator.getStablecoinInfo().proposed,
            address(6767),
            "Proposed stablecoin address should be updated"
        );

        assertEq(
            orchestrator.getStablecoinInfo().timeToExecute,
            block.timestamp + 1 days,
            "Time to execute should be set to 1 day from now"
        );
    }

    function test_unit_correct_cancelStablecoinAddressChange() public {
        vm.startPrank(ADMIN.Address);
        orchestrator.proposeStablecoinAddressChange(address(6767));
        orchestrator.cancelStablecoinAddressChange();
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().current,
            address(usdc),
            "Current stablecoin address should remain unchanged"
        );

        assertEq(
            orchestrator.getStablecoinInfo().proposed,
            address(0),
            "Proposed stablecoin address should be reset to 0"
        );

        assertEq(
            orchestrator.getStablecoinInfo().timeToExecute,
            0,
            "Time to execute should be reset to 0"
        );
    }

    function test_unit_correct_executeStablecoinAddressChange() public {
        vm.startPrank(ADMIN.Address);
        orchestrator.proposeStablecoinAddressChange(address(6767));
        skip(1 days);
        orchestrator.executeStablecoinAddressChange();
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().current,
            address(6767),
            "Current stablecoin address should be updated to the new address"
        );

        assertEq(
            orchestrator.getStablecoinInfo().proposed,
            address(0),
            "Proposed stablecoin address should be reset to 0"
        );

        assertEq(
            orchestrator.getStablecoinInfo().timeToExecute,
            0,
            "Time to execute should be reset to 0"
        );
    }

    function test_unit_correct_migrateOrchestrator() public {
        vm.startPrank(ADMIN.Address);
        orchestrator.migrateOrchestrator(address(7878), ADMIN.Address);
        vm.stopPrank();

        assertEq(
            orchestrator.getNewOrchestratorAddress(),
            address(7878),
            "Migrated orchestrator address should be updated"
        );

        assertGt(
            usdc.balanceOf(ADMIN.Address),
            0,
            "Admin should have received remaining stablecoin balance"
        );

        assertGt(
            usdc.balanceOf(address(7878)),
            0,
            "New orchestrator should have received stablecoin balance"
        );

        assertEq(
            albumDB.owner(),
            address(7878),
            "AlbumDB owner should be updated to new orchestrator"
        );
        assertEq(
            userDB.owner(),
            address(7878),
            "UserDB owner should be updated to new orchestrator"
        );
        assertEq(
            songDB.owner(),
            address(7878),
            "SongDB owner should be updated to new orchestrator"
        );
        assertEq(
            userDB.owner(),
            address(7878),
            "UserDB owner should be updated to new orchestrator"
        );
    }

    function test_unit_correct_withdrawCollectedFees() public {
        uint256 initialAdminBalance = usdc.balanceOf(ADMIN.Address);

        vm.startPrank(ADMIN.Address);

        uint256 feesAccumulatedBefore = orchestrator.getAmountCollectedInFees();

        orchestrator.withdrawCollectedFees(
            ADMIN.Address,
            feesAccumulatedBefore
        );

        uint256 feesAccumulatedAfter = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        uint256 finalAdminBalance = usdc.balanceOf(ADMIN.Address);

        assertGt(
            finalAdminBalance,
            initialAdminBalance,
            "Admin stablecoin balance should increase after withdrawing fees"
        );

        assertEq(
            feesAccumulatedAfter,
            0,
            "Collected fees in orchestrator should be reset to zero after withdrawal"
        );
    }


    function test_unit_correct_giveCollectedFeesToUser() public {
        uint256 initialUserBalance = userDB.getBalance(USER_ID);

        vm.startPrank(ADMIN.Address);

        uint256 feesAccumulatedBefore = orchestrator.getAmountCollectedInFees();

        orchestrator.giveCollectedFeesToUser(
            USER_ID,
            feesAccumulatedBefore
        );

        uint256 feesAccumulatedAfter = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        uint256 finalUserBalance = userDB.getBalance(USER_ID);

        assertGt(
            finalUserBalance,
            initialUserBalance,
            "User stablecoin balance should increase after receiving fees"
        );

        assertEq(
            feesAccumulatedAfter,
            0,
            "Collected fees in orchestrator should be reset to zero after giving to user"
        );
    }

    function test_unit_correct_setShopOperationsBreaker() public {
        uint256 netPrice = 500_000000;
        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Shop Breaker Test Song",
            ARTIST_1_ID,
            new uint256[](0),
            "https://arweave.net/mediaURI2",
            "https://arweave.net/metadataURI2",
            true,
            netPrice
        );
        _assign_song_to_album_direct(songID, 1);
        (uint256 totalPrice, ) = orchestrator.getPriceWithFee(netPrice);
        _execute_orchestrator_depositFunds(USER.Address, totalPrice);

        vm.startPrank(ADMIN.Address);
        orchestrator.setShopOperationsBreaker(false);
        vm.stopPrank();

        vm.startPrank(USER.Address);
        vm.expectRevert(ErrorsLib.ShopOperationsArePaused.selector);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        orchestrator.setShopOperationsBreaker(true);
        vm.stopPrank();

        vm.startPrank(USER.Address);
        orchestrator.purchaseSong(songID, 0);
        vm.stopPrank();

        assertEq(
            songDB.userOwnershipStatus(songID, USER_ID),
            bytes1(0x01),
            "User should own the song after purchasing with re-enabled shop breaker"
        );
    }

    function test_unit_correct_setDepositOperationsBreaker() public {
        uint256 amount = 100_000000;
        _giveUsdc(USER.Address, amount);

        vm.startPrank(USER.Address);
        usdc.approve(address(orchestrator), amount);
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        orchestrator.setDepositOperationsBreaker(false);
        vm.stopPrank();

        vm.startPrank(USER.Address);
        vm.expectRevert(ErrorsLib.DepositOperationsArePaused.selector);
        orchestrator.depositFunds(amount);
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        orchestrator.setDepositOperationsBreaker(true);
        vm.stopPrank();

        uint256 balanceBefore = userDB.getBalance(USER_ID);

        vm.startPrank(USER.Address);
        orchestrator.depositFunds(amount);
        vm.stopPrank();

        assertGt(
            userDB.getBalance(USER_ID),
            balanceBefore,
            "User balance should increase after deposit with re-enabled breaker"
        );
    }

    function test_unit_correct_setUserRegistrationBreaker() public {
        vm.startPrank(ADMIN.Address);
        orchestrator.setUserRegistrationBreaker(false);
        vm.stopPrank();

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.UserRegistrationIsPaused.selector);
        orchestrator.register(
            "wildcard",
            "https://arweave.net/wildcardURI",
            WILDCARD_ACCOUNT.Address
        );
        vm.stopPrank();

        assertEq(
            userDB.getId(WILDCARD_ACCOUNT.Address),
            0,
            "Wildcard account should not be registered after failed registration"
        );

        vm.startPrank(ADMIN.Address);
        orchestrator.setUserRegistrationBreaker(true);
        vm.stopPrank();

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        orchestrator.register(
            "wildcard",
            "https://arweave.net/wildcardURI",
            WILDCARD_ACCOUNT.Address
        );
        vm.stopPrank();

        assertGt(
            userDB.getId(WILDCARD_ACCOUNT.Address),
            0,
            "Wildcard account should be registered after re-enabling user registration breaker"
        );
    }

    function test_unit_correct_setContentRegistrationBreaker() public {
        StructsLib.RegisterSongInput[] memory inputs = new StructsLib.RegisterSongInput[](1);
        inputs[0] = StructsLib.RegisterSongInput({
            title: "Content Breaker Test Song",
            principalArtistId: ARTIST_1_ID,
            artistIDs: new uint256[](0),
            mediaURI: "https://arweave.net/mediaURI3",
            metadataURI: "https://arweave.net/metadataURI3",
            canBePurchased: false,
            netprice: 0,
            splitMetadata: new SplitterDB.Metadata[](0)
        });

        vm.startPrank(ADMIN.Address);
        orchestrator.setContentRegistrationBreaker(false);
        vm.stopPrank();

        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(ErrorsLib.ContentRegistrationIsPaused.selector);
        orchestrator.registerSong(inputs);
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        orchestrator.setContentRegistrationBreaker(true);
        vm.stopPrank();

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory songIds = orchestrator.registerSong(inputs);
        vm.stopPrank();

        assertGt(
            songIds[0],
            0,
            "Song should be registered after re-enabling content registration breaker"
        );
    }
}
