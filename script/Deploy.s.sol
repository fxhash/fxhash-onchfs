// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {FileSystem} from "src/FileSystem.sol";

contract FileSystemTest is Script {
    // Contracts
    FileSystem internal fileSystem;

    // Constants
    address internal constant GOERLI_CONTENT_STORE = 0x7c1730B7bE9424D0b983B84aEb254e3a2a105d91;
    address internal constant MAINNET_CONTENT_STORE = 0xC6806fd75745bB5F5B32ADa19963898155f9DB91;

    // State
    address internal contentStore;

    /*//////////////////////////////////////////////////////////////////////////
                                     SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        contentStore = GOERLI_CONTENT_STORE;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      RUN
    //////////////////////////////////////////////////////////////////////////*/
    function run() public virtual {
        vm.startBroadcast();
        fileSystem = new FileSystem(contentStore);
        vm.stopBroadcast();
    }
}
