// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract CreateDirectory is FileSystemTest {
    bytes32[] internal hashedNames;
    bytes32[] internal pointers;
    string[] internal names;

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
                METADATA_TYPE,
                keccak256(abi.encodePacked(hashedNames)),
                keccak256(abi.encodePacked(filePointers))
            )
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }

    function test_ReadDirectory() public {
        test_CreateDirectory();
        (names, pointers) = fileSystem.readDirectory(checksum);
        assertEq(names.length, fileNames.length);
        assertEq(pointers.length, filePointers.length);

        for (uint256 i; i < names.length; i++) {
            assertEq(names[i], fileNames[i]);
            assertEq(pointers[i], filePointers[i]);
        }
    }
}
