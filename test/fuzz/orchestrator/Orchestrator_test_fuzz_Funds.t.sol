// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

contract Orchestrator_test_fuzz_Funds is Constants {
    uint256 USER_ID;
    uint256 ARTIST_1_ID;
    uint256 WILDCARD_USER_ID;

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
        WILDCARD_USER_ID = _execute_orchestrator_register(
            "wildcard_user",
            "https://arweave.net/wildcardUserURI",
            WILDCARD_ACCOUNT.Address
        );
    }

    function test_fuzz_depositFunds(uint112 depositAmount) public {
        _giveUsdc(USER.Address, depositAmount);
        _approveUsdc(USER.Address, address(orchestrator), depositAmount);

        vm.startPrank(USER.Address);
        orchestrator.depositFunds(USER_ID, depositAmount);
        vm.stopPrank();

        // Verify the balance in UserDB
        uint256 userBalance = userDB.getMetadata(USER_ID).Balance;
        assertEq(
            userBalance,
            depositAmount,
            "User balance should match the deposited amount"
        );
    }

    function test_fuzz_depositFundsToAnotherUser(uint112 depositAmount) public {
        _giveUsdc(WILDCARD_ACCOUNT.Address, depositAmount);
        _approveUsdc(
            WILDCARD_ACCOUNT.Address,
            address(orchestrator),
            depositAmount
        );

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        orchestrator.depositFundsToAnotherUser(USER_ID, depositAmount);
        vm.stopPrank();

        uint256 wildcardUserBalance = userDB.getMetadata(USER_ID).Balance;
        assertEq(
            wildcardUserBalance,
            depositAmount,
            "Wildcard user balance should match the deposited amount"
        );
    }

    function test_fuzz_makeDonation(uint112 donationAmount) public {
        _execute_orchestrator_depositFunds(
            USER_ID,
            USER.Address,
            donationAmount
        );

        vm.startPrank(USER.Address);
        orchestrator.makeDonation(USER_ID, ARTIST_1_ID, donationAmount);
        vm.stopPrank();

        uint256 artistBalance = userDB.getMetadata(ARTIST_1_ID).Balance;
        assertEq(
            artistBalance,
            donationAmount,
            "Artist balance should match the donation amount"
        );
    }

    function test_fuzz_withdrawFunds_user(
        uint112 depositAmount,
        uint112 withdrawAmount
    ) public {
        vm.assume(withdrawAmount <= depositAmount);
        _execute_orchestrator_depositFunds(
            USER_ID,
            USER.Address,
            depositAmount
        );

        vm.startPrank(USER.Address);
        orchestrator.withdrawFunds(USER_ID, withdrawAmount);
        vm.stopPrank();

        uint256 userBalanceAfterWithdraw = userDB.getMetadata(USER_ID).Balance;
        assertEq(
            userBalanceAfterWithdraw,
            depositAmount - withdrawAmount,
            "User balance should be reduced by the withdrawn amount"
        );

        assertEq(
            usdc.balanceOf(USER.Address),
            withdrawAmount,
            "User USDC balance should increase by the withdrawn amount"
        );
    }

    function test_fuzz_withdrawFunds_artist(
        uint112 donationAmount,
        uint112 withdrawAmount
    ) public {
        vm.assume(withdrawAmount <= donationAmount);

        _execute_orchestrator_depositFunds(
            USER_ID,
            USER.Address,
            donationAmount
        );

        vm.startPrank(USER.Address);
        orchestrator.makeDonation(USER_ID, ARTIST_1_ID, donationAmount);
        vm.stopPrank();

        vm.startPrank(ARTIST_1.Address);
        orchestrator.withdrawFunds(ARTIST_1_ID, withdrawAmount);
        vm.stopPrank();

        uint256 artistBalanceAfterWithdraw = userDB
            .getMetadata(ARTIST_1_ID)
            .Balance;
        assertEq(
            artistBalanceAfterWithdraw,
            donationAmount - withdrawAmount,
            "Artist balance should be reduced by the withdrawn amount"
        );

        assertEq(
            usdc.balanceOf(ARTIST_1.Address),
            withdrawAmount,
            "Artist USDC balance should increase by the withdrawn amount"
        );
    }
}
