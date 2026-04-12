// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract Orchestrator_test_unit_revert_Administrative is Constants {
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

    function test_unit_revert_changePercentageFee__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orchestrator.changePercentageFee(500); // 5%
        vm.stopPrank();
    }

    function test_unit_revert_changePercentageFee__InvalidPercentageFee()
        public
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(ErrorsLib.InvalidPercentageFee.selector);
        orchestrator.changePercentageFee(50000); // 500%
        vm.stopPrank();

        assertEq(
            orchestrator.getPercentageFee(),
            250,
            "Percentage fee should remain at the initial 250 basis points"
        );
    }

    function test_unit_revert_proposeStablecoinAddressChange() public {
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

    function test_unit_revert_cancelStablecoinAddressChange() public {
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

    function test_unit_revert_executeStablecoinAddressChange() public {
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

    function test_unit_revert_migrateOrchestrator() public {
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

    function test_unit_revert_withdrawCollectedFees() public {
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

    function test_unit_revert_giveCollectedFeesToArtist() public {
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

    function test_unit_revert_giveCollectedFeesToUser() public {
        uint256 initialUserBalance = userDB.getBalance(USER_ID);

        vm.startPrank(ADMIN.Address);

        uint256 feesAccumulatedBefore = orchestrator.getAmountCollectedInFees();

        orchestrator.giveCollectedFeesToUser(USER_ID, feesAccumulatedBefore);

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

    function test_unit_revert_proposeStablecoinAddressChange__Unauthorized()
        public
    {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orchestrator.proposeStablecoinAddressChange(address(6767));
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().proposed,
            address(0),
            "Proposed stablecoin address should remain zero after unauthorized call"
        );
    }

    function test_unit_revert_proposeStablecoinAddressChange__ProposedAddressCannotBeZero()
        public
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(ErrorsLib.ProposedAddressCannotBeZero.selector);
        orchestrator.proposeStablecoinAddressChange(address(0));
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().proposed,
            address(0),
            "Proposed stablecoin address should remain zero after invalid call"
        );
    }

    function test_unit_revert_cancelStablecoinAddressChange__Unauthorized()
        public
    {
        vm.startPrank(ADMIN.Address);
        orchestrator.proposeStablecoinAddressChange(address(6767));
        vm.stopPrank();

        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orchestrator.cancelStablecoinAddressChange();
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().proposed,
            address(6767),
            "Proposed stablecoin address should remain unchanged after unauthorized cancel"
        );
    }

    function test_unit_revert_executeStablecoinAddressChange__Unauthorized()
        public
    {
        vm.startPrank(ADMIN.Address);
        orchestrator.proposeStablecoinAddressChange(address(6767));
        vm.stopPrank();

        skip(1 days);

        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orchestrator.executeStablecoinAddressChange();
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().current,
            address(usdc),
            "Current stablecoin address should remain unchanged after unauthorized execute"
        );
    }

    function test_unit_revert_executeStablecoinAddressChange__TimelockNotExpired()
        public
    {
        vm.startPrank(ADMIN.Address);
        orchestrator.proposeStablecoinAddressChange(address(6767));
        vm.expectRevert(ErrorsLib.TimelockNotExpired.selector);
        orchestrator.executeStablecoinAddressChange();
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().current,
            address(usdc),
            "Current stablecoin address should remain unchanged while timelock is active"
        );
    }

    function test_unit_revert_migrateOrchestrator__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orchestrator.migrateOrchestrator(address(7878), ADMIN.Address);
        vm.stopPrank();

        assertEq(
            orchestrator.getNewOrchestratorAddress(),
            address(0),
            "New orchestrator address should remain zero after unauthorized call"
        );
    }

    function test_unit_revert_migrateOrchestrator__ProposedAddressCannotBeZero()
        public
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(ErrorsLib.ProposedAddressCannotBeZero.selector);
        orchestrator.migrateOrchestrator(address(0), ADMIN.Address);
        vm.stopPrank();

        assertEq(
            orchestrator.getNewOrchestratorAddress(),
            address(0),
            "New orchestrator address should remain zero after invalid call"
        );
    }

    function test_unit_revert_withdrawCollectedFees__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orchestrator.withdrawCollectedFees(USER.Address, 1);
        vm.stopPrank();
    }

    function test_unit_revert_withdrawCollectedFees__InsufficientBalance()
        public
    {
        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.withdrawCollectedFees(ADMIN.Address, feesCollected + 1);
        uint256 feesAfter = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            feesAfter,
            feesCollected,
            "Collected fees should remain unchanged after failed withdrawal"
        );
    }

    function test_unit_revert_giveCollectedFeesToArtist__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orchestrator.giveCollectedFeesToArtist(ARTIST_1_ID, 1);
        vm.stopPrank();
    }

    function test_unit_revert_giveCollectedFeesToArtist__InsufficientBalance()
        public
    {
        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.giveCollectedFeesToArtist(
            ARTIST_1_ID,
            feesCollected + 1
        );
        uint256 feesAfter = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            feesAfter,
            feesCollected,
            "Collected fees should remain unchanged after failed give to artist"
        );
    }

    function test_unit_revert_giveCollectedFeesToArtist__UserIdDoesNotExist()
        public
    {
        uint256 nonExistentId = 99999999;

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.UserIdDoesNotExist.selector,
                nonExistentId
            )
        );
        orchestrator.giveCollectedFeesToArtist(nonExistentId, 1);
        vm.stopPrank();
    }

    function test_unit_revert_giveCollectedFeesToUser__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orchestrator.giveCollectedFeesToUser(USER_ID, 1);
        vm.stopPrank();
    }

    function test_unit_revert_giveCollectedFeesToUser__InsufficientBalance()
        public
    {
        vm.startPrank(ADMIN.Address);
        uint256 feesCollected = orchestrator.getAmountCollectedInFees();
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.giveCollectedFeesToUser(USER_ID, feesCollected + 1);
        uint256 feesAfter = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            feesAfter,
            feesCollected,
            "Collected fees should remain unchanged after failed give to user"
        );
    }

    function test_unit_revert_giveCollectedFeesToUser__UserIdDoesNotExist()
        public
    {
        uint256 nonExistentId = 99999999;

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.UserIdDoesNotExist.selector,
                nonExistentId
            )
        );
        orchestrator.giveCollectedFeesToUser(nonExistentId, 1);
        vm.stopPrank();
    }
}
