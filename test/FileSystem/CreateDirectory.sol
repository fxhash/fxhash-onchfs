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
        fileSystem.createDirectory(fileNames, filePointers);
        hashedNames = fileSystem.hashFileNames(fileNames);
        checksum = keccak256(
            abi.encodePacked(
                DIRECTORY_TYPE,
                keccak256(abi.encodePacked(hashedNames)),
                keccak256(abi.encodePacked(filePointers))
            )
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }
}
