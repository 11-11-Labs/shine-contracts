// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {Orchestrator} from "@shine/contracts/orchestrator/Orchestrator.sol";
import {SplitterDB} from "@shine/contracts/database/SplitterDB.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

contract DeployAnvilScript is Script {
    AlbumDB albumDB;
    SongDB songDB;
    UserDB userDB;
    SplitterDB splitterDB;
    Orchestrator orchestrator;
    MockUSDC mockUSDC;

    address admin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {}

    function run() public {
        address usdcAddress;
        
        vm.startBroadcast();
        mockUSDC = new MockUSDC();
        usdcAddress = address(mockUSDC);
        
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

        console.log("MockUSDC deployed at:", address(mockUSDC));
        console.log("Orchestrator deployed at:", address(orchestrator));
        console.log("AlbumDB deployed at:", address(albumDB));
        console.log("SongDB deployed at:", address(songDB));
        console.log("UserDB deployed at:", address(userDB));
        console.log("SplitterDB deployed at:", address(splitterDB));

        vm.stopBroadcast();
    }
}

contract MockUSDC is ERC20 {

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function name() public pure override returns (string memory) {
        return "Mock USDC";
    }

    function symbol() public pure override returns (string memory) {
        return "mUSDC";
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
