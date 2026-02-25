// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

contract Orchestrator_test_unit_revert_Funds is Constants {
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

    function test_unit_revert_depositFunds_InsufficientAllowance() public {
        uint256 depositAmount = 10_000_000; // 10 USDC with 6 decimals

        _giveUsdc(USER.Address, depositAmount);

        vm.startPrank(USER.Address);
        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        orchestrator.depositFunds(USER_ID, depositAmount);
        vm.stopPrank();
    }

    function test_unit_revert_depositFunds_InsufficientBalance() public {
        uint256 depositAmount = 10_000_000; // 10 USDC with 6 decimals

        _approveUsdc(USER.Address, address(orchestrator), depositAmount);

        vm.startPrank(USER.Address);
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        orchestrator.depositFunds(USER_ID, depositAmount);
        vm.stopPrank();
    }

    function test_unit_revert_depositFunds_AddressIsNotOwnerOfUserId() public {
        uint256 depositAmount = 10_000_000; // 10 USDC with 6 decimals

        _giveUsdc(USER.Address, depositAmount);
        _approveUsdc(USER.Address, address(orchestrator), depositAmount);

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.depositFunds(USER_ID, depositAmount);
        vm.stopPrank();
    }

    function test_unit_revert_depositFundsToAnotherUser() public {
        uint256 depositAmount = 5_000_000; // 5 USDC with 6 decimals

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

    function test_unit_revert_makeDonation_InsufficientBalance() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.makeDonation(USER_ID, ARTIST_1_ID, 10_000000);
        vm.stopPrank();

        uint256 artistBalance = userDB.getMetadata(ARTIST_1_ID).Balance;
        assertEq(
            artistBalance,
            0,
            "Artist balance should remain zero after failed donation"
        );
    }

    function test_unit_revert_withdrawFunds_user_AddressIsNotOwnerOfUserId()
        public
    {
        _execute_orchestrator_depositFunds(USER_ID, USER.Address, 20_000_000); // 20 USDC

        uint256 withdrawAmount = 15_000_000; // 15 USDC with 6 decimals

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.withdrawFunds(USER_ID, withdrawAmount);
        vm.stopPrank();

        uint256 userBalanceAfterWithdraw = userDB.getMetadata(USER_ID).Balance;
        assertEq(
            userBalanceAfterWithdraw,
            20_000_000,
            "User balance should remain unchanged after failed withdrawal"
        );

        assertEq(
            usdc.balanceOf(USER.Address),
            0,
            "User USDC balance should remain unchanged after failed withdrawal"
        );
    }

    function test_unit_revert_withdrawFunds_user_InsufficientBalance() public {
        _execute_orchestrator_depositFunds(USER_ID, USER.Address, 20_000_000); // 20 USDC

        uint256 withdrawAmount = 25_000_000; // 25 USDC with 6 decimals

        vm.startPrank(USER.Address);
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.withdrawFunds(USER_ID, withdrawAmount);
        vm.stopPrank();

        uint256 userBalanceAfterWithdraw = userDB.getMetadata(USER_ID).Balance;
        assertEq(
            userBalanceAfterWithdraw,
            20_000_000,
            "User balance should remain unchanged after failed withdrawal"
        );

        assertEq(
            usdc.balanceOf(USER.Address),
            0,
            "User USDC balance should remain unchanged after failed withdrawal"
        );
    }

    function test_unit_revert_withdrawFunds_artist_AddressIsNotOwnerOfUserId()
        public
    {
        _execute_orchestrator_depositFunds(USER_ID, USER.Address, 30_000_000); // 30 USDC

        vm.startPrank(USER.Address);
        orchestrator.makeDonation(USER_ID, ARTIST_1_ID, 30_000_000);
        vm.stopPrank();

        uint256 withdrawAmount = 10_000_000; // 10 USDC with 6 decimals

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.withdrawFunds(ARTIST_1_ID, withdrawAmount);
        vm.stopPrank();

        uint256 artistBalanceAfterWithdraw = userDB
            .getMetadata(ARTIST_1_ID)
            .Balance;
        assertEq(
            artistBalanceAfterWithdraw,
            30_000_000,
            "Artist balance should remain unchanged after failed withdrawal"
        );

        assertEq(
            usdc.balanceOf(ARTIST_1.Address),
            0,
            "Artist USDC balance should remain unchanged after failed withdrawal"
        );
    }

    function test_unit_revert_withdrawFunds_artist_InsufficientBalance()
        public
    {
        _execute_orchestrator_depositFunds(USER_ID, USER.Address, 20_000_000); // 20 USDC

        vm.startPrank(USER.Address);
        orchestrator.makeDonation(USER_ID, ARTIST_1_ID, 20_000_000);
        vm.stopPrank();

        uint256 withdrawAmount = 25_000_000; // 25 USDC with 6 decimals

        vm.startPrank(ARTIST_1.Address);
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        orchestrator.withdrawFunds(ARTIST_1_ID, withdrawAmount);
        vm.stopPrank();

        uint256 artistBalanceAfterWithdraw = userDB
            .getMetadata(ARTIST_1_ID)
            .Balance;
        assertEq(
            artistBalanceAfterWithdraw,
            20_000_000,
            "Artist balance should remain unchanged after failed withdrawal"
        );

        assertEq(
            usdc.balanceOf(ARTIST_1.Address),
            0,
            "Artist USDC balance should remain unchanged after failed withdrawal"
        );
    }
}
