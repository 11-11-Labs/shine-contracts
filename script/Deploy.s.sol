// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {Orchestrator} from "@shine/contracts/orchestrator/Orchestrator.sol";
import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";

contract DeployScript is Script {
    AlbumDB albumDB;
    SongDB songDB;
    UserDB userDB;
    SplitterDB splitterDB;
    Orchestrator orchestrator;

    address usdcAddress = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
    address admin = 0x5cBf2D4Bbf834912Ad0bD59980355b57695e8309;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        orchestrator = new Orchestrator(
            admin,
            address(usdcAddress),
            2_50 // 2.5% fee in basis points
        );

        albumDB = new AlbumDB(address(orchestrator));
        songDB = new SongDB(address(orchestrator));
        userDB = new UserDB(address(orchestrator));
        splitterDB = new SplitterDB(address(orchestrator));

        orchestrator.setDatabaseAddresses(
            address(albumDB),
            address(songDB),
            address(userDB),
            address(splitterDB)
        );

        console.log("Orchestrator deployed at:", address(orchestrator));
        console.log("AlbumDB deployed at:", address(albumDB));
        console.log("SongDB deployed at:", address(songDB));
        console.log("UserDB deployed at:", address(userDB));
        console.log("SplitterDB deployed at:", address(splitterDB));

        vm.stopBroadcast();
    }
}
