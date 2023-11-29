// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract CreateDirectory is FileSystemTest {
    bytes32[] internal hashedNames;

    function setUp() public override {
        super.setUp();
        fileNames = new string[](2);
        fileNames[0] = "file1";
        fileNames[1] = "file2";
        filePointers = new bytes32[](2);
        filePointers[0] = bytes32(uint256(1));
        filePointers[1] = bytes32(uint256(2));
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
        /// when file checksum doesnt exist
        fileSystem.createDirectory(fileNames, filePointers);
    }

    function test_RevertsWhen_FileNotFound() public {}

    function test_RevertsWhen_InvalidCharacters() public {
        fileNames[0] = "/";
        vm.expectRevert(INVALID_CHARACTER_ERROR);
        fileSystem.createDirectory(fileNames, filePointers);
    }

    function test_NestedDirectories() public {
        bytes32 checksum = fileSystem.createDirectory(fileNames, filePointers);
        filePointers[1] = checksum;
        fileSystem.createDirectory(fileNames, filePointers);
    }
}
