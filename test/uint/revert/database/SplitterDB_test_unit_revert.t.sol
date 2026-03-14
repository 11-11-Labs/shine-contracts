// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract SplitterDB_test_unit_revert is Constants {
    function executeBeforeSetUp() internal override {
        _splitterDB = new SplitterDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_revert_SplitterDB__register__Unauthorized() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](1);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 10000});

        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__register__DataIsEmpty() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](0);

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SplitterDB.DataIsEmpty.selector);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__register__SplitBasisPointsCannotBeZero() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](2);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 10000});
        splitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 0});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SplitterDB.SplitBasisPointsCannotBeZero.selector);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__register__TotalBasisPointsExceed() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](2);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 6000});
        splitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 5000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SplitterDB.TotalBasisPointsExceed.selector);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__register__MustSumToMaxBasisPoints() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](2);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 5000});
        splitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 3000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SplitterDB.MustSumToMaxBasisPoints.selector);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__change__Unauthorized() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](1);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 10000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();

        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _splitterDB.change(true, 1, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__change__DataIsEmpty() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](1);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 10000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SplitterDB.DataIsEmpty.selector);
        _splitterDB.change(true, 99, splitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__change__SplitBasisPointsCannotBeZero() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](1);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 10000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();

        SplitterDB.Metadata[] memory newSplitMetadata = new SplitterDB.Metadata[](2);
        newSplitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 10000});
        newSplitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 0});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SplitterDB.SplitBasisPointsCannotBeZero.selector);
        _splitterDB.change(true, 1, newSplitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__change__TotalBasisPointsExceed() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](1);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 10000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();

        SplitterDB.Metadata[] memory newSplitMetadata = new SplitterDB.Metadata[](2);
        newSplitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 6000});
        newSplitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 5000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SplitterDB.TotalBasisPointsExceed.selector);
        _splitterDB.change(true, 1, newSplitMetadata);
        vm.stopPrank();
    }

    function test_unit_revert_SplitterDB__change__MustSumToMaxBasisPoints() public {
        SplitterDB.Metadata[] memory splitMetadata = new SplitterDB.Metadata[](1);
        splitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 10000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _splitterDB.register(true, 1, splitMetadata);
        vm.stopPrank();

        SplitterDB.Metadata[] memory newSplitMetadata = new SplitterDB.Metadata[](2);
        newSplitMetadata[0] = SplitterDB.Metadata({id: 1, splitBasisPoints: 5000});
        newSplitMetadata[1] = SplitterDB.Metadata({id: 2, splitBasisPoints: 3000});

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SplitterDB.MustSumToMaxBasisPoints.selector);
        _splitterDB.change(true, 1, newSplitMetadata);
        vm.stopPrank();
    }
}
