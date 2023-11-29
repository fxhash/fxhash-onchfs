// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import "script/utils/Constants.sol";

import {FileSystem} from "src/FileSystem.sol";
import {IFileStore} from "ethfs/packages/contracts/src/IFileStore.sol";

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
        // File memory p5jsFile = IFileStore(fileStore).getFile(p5js);
        // bytes32[] memory p5checksums = new bytes32[](p5jsFile.contents.length);
        // for (uint256 i; i < p5checksums.length; i++) {
        //     p5checksums[i] = p5jsFile.contents.checksums[i];
        // }
        // File memory threejsFile = IFileStore(fileStore).getFile(threejs);
        // bytes32[] memory threejschecksums;
        vm.startBroadcast();
        fileSystem = new FileSystem(contentStore);
        vm.stopBroadcast();
    }
}
