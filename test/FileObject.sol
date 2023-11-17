// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {FileObject} from "src/FileObject.sol";
import {ContentStore} from "ethfs/packages/contracts/src/ContentStore.sol";

contract FileObjectTest is Test {
    FileObject public fileObject;
    ContentStore public contentStore;

    function setUp() public {
        fileObject = new FileObject(address(contentStore));
    }
}
