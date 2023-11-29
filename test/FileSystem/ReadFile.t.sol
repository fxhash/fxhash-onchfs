// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "test/FileSystem/FileSystemTest.t.sol";

contract ReadFile is FileSystemTest {
    bytes internal filename;
    bytes internal fileContent;
    bytes32[] internal chunkChecksums;

    function setUp() public override {
        super.setUp();
        filename = "file metadata";
        fileContent = bytes("asdf");
        (bytes32 checksum, ) = IContentStore(contentStore).addContent(fileContent);
        chunkChecksums.push(checksum);
    }

    function test_ReadFile() public {
        bytes32 checksum = fileSystem.createFile(filename, chunkChecksums);
        bytes memory initialContent = fileContent;
        fileContent = fileSystem.readFile(checksum);
        assertEq(fileContent, fileSystem.concatenateChunks(chunkChecksums));
        assertEq(fileContent, initialContent);
    }

    function test_WhenMultipleChunks() public {
        chunkChecksums.push(chunkChecksums[0]);
        bytes32 checksum = fileSystem.createFile(filename, chunkChecksums);
        bytes memory result = fileSystem.readFile(checksum);
        assertEq(result, bytes.concat(fileContent, fileContent));
    }
}
