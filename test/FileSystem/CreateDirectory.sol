// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract CreateDirectory is FileSystemTest {
    bytes internal metadata;
    bytes internal fileContent;
    bytes32[] internal chunkChecksums;
    bytes32[] internal hashedNames;
    bytes32 internal fileChecksum;

    function setUp() public override {
        super.setUp();
        metadata = "file metadata";
        fileContent = bytes("asdf");
        (bytes32 checksum, ) = IContentStore(contentStore).addContent(fileContent);
        chunkChecksums.push(checksum);
        fileChecksum = fileSystem.createFile(metadata, chunkChecksums);
        fileNames.push("file1");
        filePointers.push(fileChecksum);
    }

    function test_CreateDirectory() public {
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);
        hashedNames = fileSystem.hashFileNames(fileNames);
        checksum = keccak256(
            abi.encodePacked(
                bytes1(uint8(InodeType.Directory)),
                keccak256(abi.encodePacked(hashedNames)),
                keccak256(abi.encodePacked(filePointers))
            )
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }

    function test_EmptyDirectory() public {
        delete fileNames;
        delete filePointers;
        fileSystem.createDirectory(fileNames, filePointers);
    }

    function test_RevertsWhen_INodeNotFound() public {
        filePointers[0] = keccak256(abi.encode("NON_EXISTENT"));
        vm.expectRevert(INODE_NOT_FOUND_ERROR);
        fileSystem.createDirectory(fileNames, filePointers);
    }

    function test_RevertsWhen_InvalidCharacters() public {
        fileNames[0] = "/";
        vm.expectRevert(INVALID_CHARACTER_ERROR);
        fileSystem.createDirectory(fileNames, filePointers);
    }

    function test_NestedDirectories() public {
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);
        fileNames.push("file2");
        filePointers.push(checksum);
        fileSystem.createDirectory(fileNames, filePointers);
    }
}
