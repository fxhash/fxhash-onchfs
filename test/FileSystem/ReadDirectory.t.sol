// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract ReadDirectory is FileSystemTest {
    bytes32[] internal hashedFileNames;

    function setUp() public override {
        super.setUp();
        fileNames = new string[](2);
        fileNames[0] = "file1";
        fileNames[1] = "file2";
        filePointers = new bytes32[](2);
        filePointers[0] = bytes32(uint256(1));
        filePointers[1] = bytes32(uint256(2));
    }

    function test_ReadDirectory() public {
        fileSystem.createDirectory(fileNames, filePointers);
        hashedFileNames = fileSystem.hashFileNames(fileNames);
        checksum = keccak256(
            abi.encodePacked(
                DIRECTORY_TYPE,
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
        filePointers[1] = checksum;
        checksum = fileSystem.createDirectory(fileNames, filePointers);
    }

    function test_RevertsWhen_ChecksumDoesntExist() public {
        vm.expectRevert(INODE_NOT_FOUND_ERROR);
        fileSystem.readDirectory(checksum);
    }

    function test_RevertsWhen_ReadingFile() public {
        bytes memory metadata = "file metadata";
        bytes memory fileContent = bytes("asdf");
        (bytes32 checksum, ) = IContentStore(contentStore).addContent(fileContent);
        bytes32[] memory chunkChecksums = new bytes32[](1);
        chunkChecksums[0] = checksum;
        bytes32 fileChecksum = fileSystem.createFile(metadata, chunkChecksums);
        vm.expectRevert(DIRECTORY_NOT_FOUND_ERROR);
        fileSystem.readFile(fileChecksum);
    }
}
