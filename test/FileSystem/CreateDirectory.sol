// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract CreateDirectory is FileSystemTest {
    bytes32[] internal hashedPaths;
    bytes32[] internal pointers;
    string[] internal paths;

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
        hashedPaths = fileSystem.hashPaths(fileNames);
        checksum = keccak256(
            abi.encodePacked(
                DIRECTORY_TYPE,
                keccak256(abi.encodePacked(hashedPaths)),
                keccak256(abi.encodePacked(filePointers))
            )
        );
        assertTrue(fileSystem.inodeExists(checksum));
    }

    function test_ReadDirectory() public {
        test_CreateDirectory();
        (paths, pointers) = fileSystem.readDirectory(checksum);
        assertEq(paths.length, fileNames.length);
        assertEq(pointers.length, filePointers.length);

        for (uint256 i; i < paths.length; i++) {
            assertEq(paths[i], fileNames[i]);
            assertEq(pointers[i], filePointers[i]);
        }
    }
}
