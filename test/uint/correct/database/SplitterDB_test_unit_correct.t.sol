// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";

contract SplitterDB_test_unit_correct is Constants {
    function executeBeforeSetUp() internal override {
        _splitterDB = new SplitterDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_correct_SplitterDB__register() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            3
        );
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 5000});
        splitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 3000});
        splitMetadata[2] = SplitterDB.Metadata({id: 3, splitBasisPoints: 2000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();

        SplitterDB.Metadata[] memory returnedMetadata = _splitterDB.getSplits(
            true,
            1
        );
        assertEq(
            returnedMetadata.length,
            3,
            "Returned metadata length should be 3"
        );
        assertEq(returnedMetadata[0].id, 1, "First recipient ID should be 1");
        assertEq(
            returnedMetadata[0].splitBasisPoints,
            5000,
            "First recipient basis points should be 5000"
        );
        assertEq(returnedMetadata[1].id, 2, "Second recipient ID should be 2");
        assertEq(
            returnedMetadata[1].splitBasisPoints,
            3000,
            "Second recipient basis points should be 3000"
        );
        assertEq(returnedMetadata[2].id, 3, "Third recipient ID should be 3");
        assertEq(
            returnedMetadata[2].splitBasisPoints,
            2000,
            "Third recipient basis points should be 2000"
        );
    }

    function test_unit_correct_SplitterDB__change() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            3
        );
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 5000});
        splitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 3000});
        splitMetadata[2] = SplitterDB.Metadata({id: 3, splitBasisPoints: 2000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();

        // change the splits
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 4000});
        splitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 4000});
        splitMetadata[2] = SplitterDB.Metadata({id: 3, splitBasisPoints: 2000});
        vm.startPrank(FAKE_ORCHESTRATOR.Address);   
        _splitterDB.change(true, 1, splitMetadata);
        vm.stopPrank();
        SplitterDB.Metadata[] memory returnedMetadata = _splitterDB.getSplits(
            true,
            1
        );
        assertEq(
            returnedMetadata.length,
            3,
            "Returned metadata length should be 3"
        );
        assertEq(returnedMetadata[0].id, 1, "First recipient ID should be 1");
        assertEq(
            returnedMetadata[0].splitBasisPoints,
            4000,
            "First recipient basis points should be 4000"
        );
        assertEq(returnedMetadata[1].id, 2, "Second recipient ID should be 2");
        assertEq(
            returnedMetadata[1].splitBasisPoints,
            4000,
            "Second recipient basis points should be 4000"
        );
        assertEq(returnedMetadata[2].id, 3, "Third recipient ID should be 3");
        assertEq(
            returnedMetadata[2].splitBasisPoints,
            2000,
            "Third recipient basis points should be 2000"
        );
    }
}
