// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {Orchestrator} from "@shine/contracts/orchestrator/Orchestrator.sol";
import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";

interface IOrchestrator {
    function migrateOrchestrator(
        address orchestratorAddressToMigrate,
        address accountToTransferCollectedFees
    ) external;
}

contract DeployScript is Script {
    struct DatabaseAddressMainnet {
        address albumDB;
        address songDB;
        address userDB;
        address splitterDB;
    }

    Orchestrator newOrchestrator;
    uint256 ArbSepoliaChainId = 421614;
    uint256 ArbMainnet = 42161;

    address usdcAddressMainnet = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address usdcAddressTestnet = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
    address admin = 0x5cBf2D4Bbf834912Ad0bD59980355b57695e8309;
    address oldOrchestratorAddress = 0xe138F832cB4994839dB0F79D11D0DADA0d69e3F5;
    DatabaseAddressMainnet databaseAddressMainnet =
        DatabaseAddressMainnet({
            albumDB: 0x3419C1F2d26C1c37092a28Cd3a56128d2d25AbD7,
            songDB: 0x1216c31f846805234F5b4a46852cC36Ac571295E,
            userDB: 0x784876a50639F93e11a6C57012052E57d377b67b,
            splitterDB: 0x8D10eD1d0F396d970a7e9CF9587fA79b0B9905aa
        });

    function setUp() public {}

    function run() public {
        address usdcAddress;
        IOrchestrator oldOrchestrator = IOrchestrator(oldOrchestratorAddress);

        if (block.chainid == ArbSepoliaChainId)
            usdcAddress = usdcAddressTestnet;
        else if (block.chainid == ArbMainnet) usdcAddress = usdcAddressMainnet;
        else revert("Unsupported chain");

        vm.startBroadcast();

        newOrchestrator = new Orchestrator(
            admin,
            address(usdcAddress),
            2_50 // 2.5% fee in basis points
        );

        oldOrchestrator.migrateOrchestrator(address(newOrchestrator), admin);

        newOrchestrator.setDatabaseAddresses(
            databaseAddressMainnet.albumDB,
            databaseAddressMainnet.songDB,
            databaseAddressMainnet.userDB,
            databaseAddressMainnet.splitterDB
        );

        console.log("New Orchestrator deployed at:", address(newOrchestrator));
        console.log("AlbumDB:", address(databaseAddressMainnet.albumDB));
        console.log("SongDB:", address(databaseAddressMainnet.songDB));
        console.log("UserDB:", address(databaseAddressMainnet.userDB));
        console.log("SplitterDB:", address(databaseAddressMainnet.splitterDB));

        vm.stopBroadcast();
    }
}
