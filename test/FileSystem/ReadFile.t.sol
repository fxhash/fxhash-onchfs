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
        bytes32 checksum1 = fileSystem.createFile(bytes("file1"), chunkChecksums);
        bytes32 checksum2 = fileSystem.createFile(bytes("file2"), chunkChecksums);
        fileNames = new string[](2);
        fileNames[0] = "file1";
        fileNames[1] = "file2";
        filePointers = new bytes32[](2);
        filePointers[0] = checksum1;
        filePointers[1] = checksum2;
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);
        vm.expectRevert(FILE_NOT_FOUND_ERROR);
        fileSystem.readFile(checksum);
    }

    function test_WhenMultipleChunks() public {
        bytes memory fileContent2 = bytes("hjkl");
        (bytes32 content2Checksum, ) = IContentStore(contentStore).addContent(fileContent2);
        chunkChecksums.push(content2Checksum);
        bytes32 checksum = fileSystem.createFile(metadata, chunkChecksums);
        bytes memory result = fileSystem.readFile(checksum);
        assertEq(result, bytes.concat(fileContent, fileContent2));
    }

    function test_keccak256() public {
        bytes32[] memory _chunkPointers;
        console.logBytes32(keccak256(abi.encodePacked(_chunkPointers)));
    }
}
