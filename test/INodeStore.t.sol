// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {INodeStore} from "src/INodeStore.sol";
import {ContentStore} from "ethfs/packages/contracts/src/ContentStore.sol";
import {IContentStore} from "ethfs/packages/contracts/src/IContentStore.sol";
import {SSTORE2} from "sstore2/SSTORE2.sol";

contract INodeStoreTest is Test {
    INodeStore internal nodeStore;
    IContentStore internal contentStore;

    function setUp() public {
        contentStore = IContentStore(address(new MockContentStore()));
        nodeStore = new INodeStore(address(contentStore));
    }

    function testCreateFile() public {
        bytes memory metadata = "file metadata";
        bytes32[] memory chunkPointers = new bytes32[](2);
        chunkPointers[0] = bytes32(uint256(1));
        chunkPointers[1] = bytes32(uint256(2));

        nodeStore.createFile(metadata, chunkPointers);

        bytes32 checksum = keccak256(
            abi.encodePacked(bytes1(0x01), keccak256(abi.encodePacked(chunkPointers)), keccak256(metadata))
        );

        assertTrue(nodeStore.inodeExists(checksum));

        // (string[] memory names, bytes32[] memory fileInodePointers) = nodeStore.readDirectory(checksum);
        //
        // assertEq(names.length, 0);
        // assertEq(fileInodePointers.length, 0);
        //
        // bytes memory fileContent = nodeStore.readFile(checksum);
        // assertEq(fileContent, concatenateChunks(chunkPointers));
    }

    function testCreateDirectory() public {
        string[] memory names = new string[](2);
        names[0] = "file1";
        names[1] = "file2";

        bytes32[] memory fileInodePointers = new bytes32[](2);
        fileInodePointers[0] = bytes32(uint256(1));
        fileInodePointers[1] = bytes32(uint256(2));

        nodeStore.createDirectory(names, fileInodePointers);

        bytes32 checksum = keccak256(
            abi.encodePacked(
                bytes1(0x00),
                keccak256(abi.encodePacked(hashNames(names))),
                keccak256(abi.encodePacked(fileInodePointers))
            )
        );

        assertTrue(nodeStore.inodeExists(checksum));

        // (string[] memory readNames, bytes32[] memory readFileInodePointers) = nodeStore.readDirectory(checksum);
        //
        // assertEq(readNames.length, names.length);
        // assertEq(readFileInodePointers.length, fileInodePointers.length);
        //
        // for (uint256 i = 0; i < names.length; i++) {
        //     assertEq(readNames[i], names[i]);
        //     assertEq(readFileInodePointers[i], fileInodePointers[i]);
        // }
    }

    function hashNames(string[] memory _names) internal pure returns (bytes32[] memory) {
        uint256 length = _names.length;
        bytes32[] memory hashedNames = new bytes32[](length);
        for (uint256 i; i < length; i++) {
            hashedNames[i] = keccak256(bytes(_names[i]));
        }
        return hashedNames;
    }

    function concatenateChunks(bytes32[] memory _chunkPointers) internal view returns (bytes memory) {
        bytes memory fileContent;
        for (uint256 i = 0; i < _chunkPointers.length; i++) {
            bytes32 chunkChecksum = _chunkPointers[i];
            bytes memory chunkContent = SSTORE2.read(address(contentStore.getPointer(chunkChecksum)));
            fileContent = abi.encodePacked(fileContent, chunkContent);
        }
        return fileContent;
    }
}

contract MockContentStore {
    function getPointer(bytes32 _checksum) external pure returns (address) {
        return address(uint160(uint256(_checksum)));
    }
}
