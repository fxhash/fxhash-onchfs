// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {FileSystem} from "src/FileSystem.sol";

import "script/utils/Constants.sol";

contract FileSystemTest is Script {
    // Contracts
    FileSystem internal fileSystem;

    // State
    address internal contentStore;
    address internal fileStore;

    /*//////////////////////////////////////////////////////////////////////////
                                     SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        contentStore = (block.chainid == MAINNET) ? MAINNET_CONTENT_STORE : GOERLI_CONTENT_STORE;
        fileStore = (block.chainid == MAINNET) ? MAINNET_FILE_STORE : GOERLI_FILE_STORE;
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
