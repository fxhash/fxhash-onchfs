// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {INodeStore} from "src/INodeStore.sol";
import {ContentStore} from "ethfs/packages/contracts/src/ContentStore.sol";

contract INodeStoreTest is Test {
    INodeStore public inodeStore;
    ContentStore public contentStore;

    function setUp() public {
        inodeStore = new INodeStore(address(contentStore));
    }

    function test_True() public {
        assertTrue(true);
    }
}
