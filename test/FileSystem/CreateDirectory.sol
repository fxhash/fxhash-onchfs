// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract CreateDirectory is FileSystemTest {
    bytes32[] internal hashedNames;
    bytes32[] internal readPointers;
    string[] internal readNames;

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
        hashedNames = fileSystem.hashNames(fileNames);
        checksum = keccak256(
            abi.encodePacked(
                bytes1(0x00),
                keccak256(abi.encodePacked(hashedNames)),
                keccak256(abi.encodePacked(filePointers))
            )
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }

    function test_ReadDirectory() public {
        test_CreateDirectory();
        (readNames, readPointers) = fileSystem.readDirectory(checksum);
        assertEq(readNames.length, fileNames.length);
        assertEq(readPointers.length, filePointers.length);

        for (uint256 i; i < readNames.length; i++) {
            assertEq(readNames[i], fileNames[i]);
            assertEq(readPointers[i], filePointers[i]);
        }
    }
}
