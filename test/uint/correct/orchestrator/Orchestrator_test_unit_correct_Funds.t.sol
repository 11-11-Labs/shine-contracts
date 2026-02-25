// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";


contract Orchestrator_test_unit_correct_Funds is Constants {
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

    function test_unit_correct_depositFunds() public {
        uint256 depositAmount = 10_000_000; // 10 USDC with 6 decimals

        _giveUsdc(USER.Address, depositAmount);
        _approveUsdc(USER.Address, address(orchestrator), depositAmount);

        vm.startPrank(USER.Address);
        orchestrator.depositFunds(USER_ID, depositAmount);
        vm.stopPrank();

        // Verify the balance in UserDB
        uint256 userBalance = userDB.getMetadata(USER_ID).Balance;
        assertEq(userBalance, depositAmount, "User balance should match the deposited amount");
    }

    function test_unit_correct_depositFundsToAnotherUser() public {
        uint256 depositAmount = 5_000_000; // 5 USDC with 6 decimals

        _giveUsdc(WILDCARD_ACCOUNT.Address, depositAmount);
        _approveUsdc(WILDCARD_ACCOUNT.Address, address(orchestrator), depositAmount);

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

    function test_unit_correct_makeDonation() public {
        uint256 donationAmount = 2_000_000; // 2 USDC with 6 decimals

        _execute_orchestrator_depositFunds(USER_ID, USER.Address, donationAmount);

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

    function test_unit_correct_withdrawFunds_user() public {
        _execute_orchestrator_depositFunds(USER_ID, USER.Address,  20_000_000); // 20 USDC

        uint256 withdrawAmount = 15_000_000; // 15 USDC with 6 decimals

        vm.startPrank(USER.Address);
        orchestrator.withdrawFunds(false, USER_ID, withdrawAmount);
        vm.stopPrank();

        uint256 userBalanceAfterWithdraw = userDB.getMetadata(USER_ID).Balance;
        assertEq(
            userBalanceAfterWithdraw,
            5_000_000,
            "User balance should be reduced by the withdrawn amount"
        );

        assertEq(
            usdc.balanceOf(USER.Address),
            withdrawAmount,
            "User USDC balance should increase by the withdrawn amount"
        );
    }

    function test_unit_correct_withdrawFunds_artist() public {

        ///@dev First, make a donation to the artist to have a balance to withdraw

        uint256 donationAmount = 30_000_000; // 30 USDC with 6 decimals

        _execute_orchestrator_depositFunds(USER_ID, USER.Address, donationAmount);

        vm.startPrank(USER.Address);
        orchestrator.makeDonation(USER_ID, ARTIST_1_ID, donationAmount);
        vm.stopPrank();

        ///@dev Now, withdraw funds as the artist

        uint256 withdrawAmount = 10_000_000; // 10 USDC with 6 decimals

        vm.startPrank(ARTIST_1.Address);
        orchestrator.withdrawFunds( ARTIST_1_ID, withdrawAmount);
        vm.stopPrank();

        uint256 artistBalanceAfterWithdraw = userDB.getMetadata(ARTIST_1_ID).Balance;
        assertEq(
            artistBalanceAfterWithdraw,
            20_000_000,
            "Artist balance should be reduced by the withdrawn amount"
        );

        assertEq(
            usdc.balanceOf(ARTIST_1.Address),
            withdrawAmount,
            "Artist USDC balance should increase by the withdrawn amount"
        );

    }


}
