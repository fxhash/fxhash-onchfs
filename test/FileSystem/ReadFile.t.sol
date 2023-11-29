// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract ReadFile is FileSystemTest {
    bytes internal metadata;
    bytes internal fileContent;
    bytes32[] internal chunkChecksums;

    function setUp() public override {
        super.setUp();
        metadata = "file metadata";
        fileContent = bytes("asdf");
        (bytes32 checksum, ) = IContentStore(contentStore).addContent(fileContent);
        chunkChecksums.push(checksum);
    }

    function test_ReadFile() public {
        bytes32 checksum = fileSystem.createFile(metadata, chunkChecksums);
        bytes memory initialContent = fileContent;
        fileContent = fileSystem.readFile(checksum);
        assertEq(fileContent, fileSystem.concatenateChunks(chunkChecksums));
        assertEq(fileContent, initialContent);
    }

    function test_RevertsWhen_ChecksumDoesntExist() public {
        vm.expectRevert(INODE_NOT_FOUND_ERROR);
        fileSystem.readFile(checksum);
    }

    function test_RevertsWhen_ReadingDirectory() public {
        fileNames = new string[](2);
        fileNames[0] = "file1";
        fileNames[1] = "file2";
        filePointers = new bytes32[](2);
        filePointers[0] = bytes32(uint256(1));
        filePointers[1] = bytes32(uint256(2));
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);
        vm.expectRevert(FILE_NOT_FOUND_ERROR);
        fileSystem.readFile(checksum);
    }

    function test_WhenMultipleChunks() public {
        chunkChecksums.push(chunkChecksums[0]);
        bytes32 checksum = fileSystem.createFile(metadata, chunkChecksums);
        bytes memory result = fileSystem.readFile(checksum);
        assertEq(result, bytes.concat(fileContent, fileContent));
    }
}
