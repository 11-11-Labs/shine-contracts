// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";

contract SplitterDB_test_fuzz is Constants {
    function executeBeforeSetUp() internal override {
        _splitterDB = new SplitterDB(FAKE_ORCHESTRATOR.Address);
    }

    struct RegisterInputs {
        bool isAlbumId;
        uint256 id;
        SplitterDB.Metadata[20] splitMetadata;
        uint8 seed;
    }

    function test_fuzz_SplitterDB__set(
        RegisterInputs memory inputs
    ) public {
        uint256 numberOfRecipients = bound(inputs.seed, 1, 15);
        // calculate split basis points for each recipient so that the total is 10000 (100%)
        uint256[] memory splitBasisPoints = new uint256[](numberOfRecipients);
        uint256 totalBasisPoints;
        for (uint256 i; i < numberOfRecipients; ) {
            splitBasisPoints[i] = uint256(10000 / numberOfRecipients);
            totalBasisPoints += splitBasisPoints[i];
            unchecked {
                ++i;
            }
        }
        // verify that total basis points is 10000 (100%) if not adjust the last recipient's basis points
        if (totalBasisPoints != 10000) {
            splitBasisPoints[numberOfRecipients - 1] +=
                10000 -
                totalBasisPoints;
        }
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            numberOfRecipients
        );
        for (uint256 i; i < numberOfRecipients; ) {
            splitMetadata[i] = SplitterDB.Metadata({
                id: i + 1,
                splitBasisPoints: splitBasisPoints[i]
            });
            unchecked {
                ++i;
            }
        }

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.set(inputs.isAlbumId, inputs.id, splitMetadata);
        vm.stopPrank();

        SplitterDB.Metadata[] memory returnedMetadata = _splitterDB.getSplits(
            inputs.isAlbumId,
            inputs.id
        );

        assertEq(
            returnedMetadata.length,
            numberOfRecipients,
            "Returned metadata length should match number of recipients"
        );

        for (uint256 i; i < numberOfRecipients; ) {
            assertEq(
                returnedMetadata[i].id,
                splitMetadata[i].id,
                "Returned metadata ID should match set metadata ID"
            );
            assertEq(
                returnedMetadata[i].splitBasisPoints,
                splitMetadata[i].splitBasisPoints,
                "Returned metadata split basis points should match set metadata split basis points"
            );
            unchecked {
                ++i;
            }
        }
    }

    function test_fuzz_SplitterDB__set_updateExistingSplit(
        RegisterInputs memory firstInputs,
        RegisterInputs memory secondInputs
    ) public {
        // First set of splits
        uint256 numberOfRecipients = bound(firstInputs.seed, 1, 15);
        uint256[] memory splitBasisPoints = new uint256[](numberOfRecipients);
        uint256 totalBasisPoints;
        for (uint256 i; i < numberOfRecipients; ) {
            splitBasisPoints[i] = uint256(10000 / numberOfRecipients);
            totalBasisPoints += splitBasisPoints[i];
            unchecked {
                ++i;
            }
        }
        if (totalBasisPoints != 10000) {
            splitBasisPoints[numberOfRecipients - 1] +=
                10000 -
                totalBasisPoints;
        }

        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](
            numberOfRecipients
        );
        for (uint256 i; i < numberOfRecipients; ) {
            splitMetadata[i] = SplitterDB.Metadata({
                id: i + 1,
                splitBasisPoints: splitBasisPoints[i]
            });
            unchecked {
                ++i;
            }
        }
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.set(
            firstInputs.isAlbumId,
            firstInputs.id,
            splitMetadata
        );
        vm.stopPrank();

        // Second set of splits (update existing)
        uint256 numberOfChangeRecipients = bound(secondInputs.seed, 1, 15);
        uint256[] memory splitBasisPointsChange = new uint256[](numberOfChangeRecipients);
        uint256 totalBasisPointsChange = 0;
        for (uint256 i; i < numberOfChangeRecipients; ) {
            splitBasisPointsChange[i] = uint256(10000 / numberOfChangeRecipients);
            totalBasisPointsChange += splitBasisPointsChange[i];
            unchecked {
                ++i;
            }
        }
        if (totalBasisPointsChange != 10000) {
            splitBasisPointsChange[numberOfChangeRecipients - 1] +=
                10000 -
                totalBasisPointsChange;
        }
        SplitterDB.Metadata[] memory splitChangeMetadata = new SplitterDB.Metadata[](numberOfChangeRecipients);
        for (uint256 i; i < numberOfChangeRecipients; ) {
            splitChangeMetadata[i] = SplitterDB.Metadata({
                id: i + 1,
                splitBasisPoints: splitBasisPointsChange[i]
            });
            unchecked {
                ++i;
            }
        }
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.set(
            firstInputs.isAlbumId,
            firstInputs.id,
            splitChangeMetadata
        );
        vm.stopPrank();
        SplitterDB.Metadata[] memory returnedMetadata = _splitterDB.getSplits(
            firstInputs.isAlbumId,
            firstInputs.id
        );
        assertEq(
            returnedMetadata.length,
            numberOfChangeRecipients,
            "Returned metadata length should match number of recipients after change"
        );
        for (uint256 i; i < numberOfChangeRecipients; ) {
            assertEq(
                returnedMetadata[i].id,
                splitChangeMetadata[i].id,
                "Returned metadata ID should match updated metadata ID"
            );
            assertEq(
                returnedMetadata[i].splitBasisPoints,
                splitChangeMetadata[i].splitBasisPoints,
                "Returned metadata split basis points should match updated metadata split basis points"
            );
            unchecked {
                ++i;
            }
        }
    }
}
