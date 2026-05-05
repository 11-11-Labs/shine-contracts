// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

contract Orchestrator_test_fuzz_Administrative is Constants {
    uint256 USER_ID;
    uint256 ARTIST_1_ID;

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

        uint256 netPrice = 1_000_000;

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

    function test_fuzz_changePercentageFee(uint16 fee) public {
        vm.assume(fee <= 10000);

        vm.startPrank(ADMIN.Address);
        orchestrator.changePercentageFee(fee);
        vm.stopPrank();

        assertEq(orchestrator.getPercentageFee(), fee, "Percentage fee should be updated");
    }

    function test_fuzz_proposeStablecoinAddressChange(address newAddress) public {
        vm.assume(newAddress != address(0));

        vm.startPrank(ADMIN.Address);
        orchestrator.proposeStablecoinAddressChange(newAddress);
        vm.stopPrank();

        assertEq(
            orchestrator.getStablecoinInfo().current,
            address(usdc),
            "Current stablecoin should remain unchanged"
        );
        assertEq(
            orchestrator.getStablecoinInfo().proposed,
            newAddress,
            "Proposed stablecoin should be updated"
        );
        assertEq(
            orchestrator.getStablecoinInfo().timeToExecute,
            block.timestamp + 1 days,
            "Time to execute should be set to 1 day from now"
        );
    }

    function test_fuzz_withdrawCollectedFees(uint256 withdrawAmount) public {
        vm.startPrank(ADMIN.Address);
        uint256 feesAccumulated = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        withdrawAmount = bound(withdrawAmount, 0, feesAccumulated);

        uint256 initialAdminBalance = usdc.balanceOf(ADMIN.Address);

        vm.startPrank(ADMIN.Address);
        orchestrator.withdrawCollectedFees(ADMIN.Address, withdrawAmount);
        uint256 feesAfter = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            usdc.balanceOf(ADMIN.Address),
            initialAdminBalance + withdrawAmount,
            "Admin balance should increase by the withdrawn amount"
        );
        assertEq(
            feesAfter,
            feesAccumulated - withdrawAmount,
            "Fees after withdrawal should be reduced correctly"
        );
    }

    function test_fuzz_giveCollectedFeesToUser(uint256 giveAmount) public {
        vm.startPrank(ADMIN.Address);
        uint256 feesAccumulated = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        giveAmount = bound(giveAmount, 0, feesAccumulated);

        uint256 initialUserBalance = userDB.getBalance(USER_ID);

        vm.startPrank(ADMIN.Address);
        orchestrator.giveCollectedFeesToUser(USER_ID, giveAmount);
        uint256 feesAfter = orchestrator.getAmountCollectedInFees();
        vm.stopPrank();

        assertEq(
            userDB.getBalance(USER_ID),
            initialUserBalance + giveAmount,
            "User balance should increase by the given amount"
        );
        assertEq(
            feesAfter,
            feesAccumulated - giveAmount,
            "Fees after distribution should be reduced correctly"
        );
    }
}
