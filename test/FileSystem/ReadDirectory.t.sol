// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract ReadDirectory is FileSystemTest {
    bytes32[] internal hashedFileNames;
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

    function test_ReadDirectory() public {
        fileSystem.createDirectory(fileNames, filePointers);
        hashedFileNames = fileSystem.hashFileNames(fileNames);
        checksum = keccak256(
            abi.encodePacked(
                bytes1(uint8(InodeType.Directory)),
                keccak256(abi.encodePacked(hashedFileNames)),
                keccak256(abi.encodePacked(filePointers))
            )
        );

        bytes32[] memory pointers;
        string[] memory fileNameResults;
        (fileNameResults, pointers) = fileSystem.readDirectory(checksum);
        assertEq(fileNameResults.length, fileNames.length);
        assertEq(pointers.length, filePointers.length);

        for (uint256 i; i < fileNameResults.length; i++) {
            assertEq(fileNameResults[i], fileNames[i]);
            assertEq(pointers[i], filePointers[i]);
        }
    }

    function test_NestedDirectory() public {
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);
        fileNames.push("file2");
        filePointers.push(checksum);
        checksum = fileSystem.createDirectory(fileNames, filePointers);
    }

    function test_RevertsWhen_ChecksumDoesntExist() public {
        vm.expectRevert(INODE_NOT_FOUND_ERROR);
        fileSystem.readDirectory(checksum);
    }

    function test_RevertsWhen_ReadingFile() public {
        vm.expectRevert(DIRECTORY_NOT_FOUND_ERROR);
        fileSystem.readDirectory(fileChecksum);
    }
}
