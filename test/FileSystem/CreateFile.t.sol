// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract CreateFile is FileSystemTest {
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

    function test_CreateFile() public {
        fileSystem.createFile(metadata, chunkChecksums);
        checksum = keccak256(
            abi.encodePacked(
                bytes1(uint8(InodeType.File)),
                keccak256(abi.encodePacked(chunkChecksums)),
                keccak256(metadata)
            )
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }

    function test_ReturnsCheckSum_DuplicateFile() public {
        fileSystem.createFile(metadata, chunkChecksums);

        fileSystem.createFile(metadata, chunkChecksums);
    }

    function test_RevertsWhen_ChunkPointerReferencesEmptyChunk() public {
        delete chunkChecksums;
        chunkChecksums = new bytes32[](1);
        vm.expectRevert(CHUNK_NOT_FOUND_ERROR);
        fileSystem.createFile(metadata, chunkChecksums);
    }

    function test_SameContent_UniqueMetadata_DifferentFile() public {
        bytes32 checksum1 = fileSystem.createFile(metadata, chunkChecksums);
        bytes32 checksum2 = fileSystem.createFile(bytes("null"), chunkChecksums);
        assertTrue(checksum1 != checksum2);
    }

    function test_WhenMultipleChunks() public {
        chunkChecksums.push(chunkChecksums[0]);
        fileSystem.createFile(metadata, chunkChecksums);
        checksum = keccak256(
            abi.encodePacked(
                bytes1(uint8(InodeType.File)),
                keccak256(abi.encodePacked(chunkChecksums)),
                keccak256(metadata)
            )
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }
}
