// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract GetInodeAt is FileSystemTest {
    function setUp() public override {
        super.setUp();
        fileChecksum = fileSystem.createFile(metadata, chunkChecksums);
        fileNames.push("file1");
        filePointers.push(fileChecksum);
    }

    function test_GetInodeAt() public {
        bytes32 expectedChecksum = fileSystem.createDirectory(fileNames, filePointers);
        filePointers.push(expectedChecksum);
        fileNames.push("file");
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);

        string[] memory pathSegments = new string[](1);
        pathSegments[0] = "file";
        (bytes32 result, ) = fileSystem.getInodeAt(checksum, pathSegments);
        assertEq(result, expectedChecksum);
    }

    function test_RevertsWhen_InodeDoesntExistAtPath() public {
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);
        string[] memory pathSegments = new string[](1);
        pathSegments[0] = "file";
        vm.expectRevert(INODE_NOT_FOUND_ERROR);
        fileSystem.getInodeAt(checksum, pathSegments);
    }

    function test_NoPathSegments() public {
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);
        string[] memory pathSegments = new string[](0);
        (bytes32 result, ) = fileSystem.getInodeAt(checksum, pathSegments);
        assertEq(checksum, result);
    }

    function test_RevertsWhen_StartingInodeDoesntExist() public {
        fileSystem.createDirectory(fileNames, filePointers);

        string[] memory pathSegments = new string[](1);
        pathSegments[0] = "file";
        vm.expectRevert(INODE_NOT_FOUND_ERROR);
        fileSystem.getInodeAt(bytes32(0), pathSegments);
    }
}
