// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract CreateFile is FileSystemTest {
    bytes internal filename;
    bytes internal fileContent;
    bytes32[] internal chunkChecksums;

    function setUp() public override {
        super.setUp();
        filename = "file metadata";
        fileContent = bytes("asdf");
        (bytes32 checksum, ) = IContentStore(contentStore).addContent(fileContent);
        chunkChecksums.push(checksum);
    }

    function test_CreateFile() public {
        fileSystem.createFile(filename, chunkChecksums);
        checksum = keccak256(
            abi.encodePacked(FILE_TYPE, keccak256(abi.encodePacked(chunkChecksums)), keccak256(filename))
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }

    function test_WhenMultipleChunks() public {
        chunkChecksums.push(chunkChecksums[0]);
        fileSystem.createFile(filename, chunkChecksums);
        checksum = keccak256(
            abi.encodePacked(FILE_TYPE, keccak256(abi.encodePacked(chunkChecksums)), keccak256(filename))
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }
}
