// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract CreateFile is FileSystemTest {
    bytes internal metadata;
    bytes internal fileContent;
    bytes32[] internal chunkPointers;

    function setUp() public override {
        super.setUp();
        metadata = "file metadata";
        chunkPointers = new bytes32[](2);
        chunkPointers[0] = bytes32(uint256(1));
        chunkPointers[1] = bytes32(uint256(2));
    }

    function test_CreateFile() public {
        fileSystem.createFile(metadata, chunkPointers);
        checksum = keccak256(
            abi.encodePacked(METADATA_TYPE, keccak256(abi.encodePacked(chunkPointers)), keccak256(metadata))
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }

    function xtest_ReadFile() public {
        test_CreateFile();
        (fileNames, filePointers) = fileSystem.readDirectory(checksum);
        assertEq(fileNames.length, 0);
        assertEq(filePointers.length, 0);

        fileContent = fileSystem.readFile(checksum);
        assertEq(fileContent, fileSystem.concatenateChunks(chunkPointers));
    }
}
