// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import "script/utils/Constants.sol";

import {FileSystem} from "src/FileSystem.sol";

contract FileSystemTest is Script {
    // Contracts
    FileSystem internal fileSystem;

    // State
    address internal contentStore;

    /*//////////////////////////////////////////////////////////////////////////
                                     SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        contentStore = (block.chainid == MAINNET) ? MAINNET_CONTENT_STORE : GOERLI_CONTENT_STORE;
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
