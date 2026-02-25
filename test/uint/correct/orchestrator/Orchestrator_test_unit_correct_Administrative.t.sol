// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";

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

        (uint256 totalPrice, ) = orchestrator.getPriceWithFee(netPrice);

        _execute_orchestrator_depositFunds(USER_ID, USER.Address, totalPrice);

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


    function test_unit_correct_giveCollectedFeesToArtist() public {
        uint256 initialArtistBalance = userDB.getBalance(ARTIST_1_ID);

        vm.startPrank(ADMIN.Address);

        uint256 feesAccumulatedBefore = orchestrator.getAmountCollectedInFees();

        orchestrator.giveCollectedFeesToArtist(
            ARTIST_1_ID,
            feesAccumulatedBefore
        );

        uint256 feesAccumulatedAfter = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        uint256 finalArtistBalance = userDB.getBalance(ARTIST_1_ID);

        assertGt(
            finalArtistBalance,
            initialArtistBalance,
            "Artist stablecoin balance should increase after receiving fees"
        );

        assertEq(
            feesAccumulatedAfter,
            0,
            "Collected fees in orchestrator should be reset to zero after giving to artist"
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
}
