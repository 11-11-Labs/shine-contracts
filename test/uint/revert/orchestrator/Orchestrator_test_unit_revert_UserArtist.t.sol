// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";

contract Orchestrator_test_unit_revert_UserArtist is Constants {
    function test_unit_revert_chnageBasicData_AddressIsNotOwnerOfUserId()
        public
    {
        uint256 userId = _execute_orchestrator_register(
            "initial_user",
            "https://arweave.net/initialUserURI",
            USER.Address
        );

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.chnageBasicData(
            userId,
            "updated_user",
            "https://arweave.net/updatedUserURI"
        );
        vm.stopPrank();
    }

    function test_unit_revert_changeAddress_AddressIsNotOwnerOfUserId() public {
        uint256 userId = _execute_orchestrator_register(
            "user_name",
            "https://arweave.net/userURI",
            USER.Address
        );

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.changeAddress(userId, WILDCARD_ACCOUNT.Address);
        vm.stopPrank();
    }
}
