// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ContentStore} from "ethfs/packages/contracts/src/ContentStore.sol";

contract FileObject {
    // Define the structure of a file
    struct File {
        bytes metadata;
        bytes32[] chunkPointers;
    }

    // Define the structure of a directory
    struct Directory {
        string[] names;
        bytes32[] inodePointers;
    }

    // Define the enumeration for inode types
    enum InodeType {
        File,
        Directory
    }

    // Define the structure of an inode
    struct Inode {
        InodeType inodeType;
        File file;
        Directory directory;
    }

    // Define the mapping of inodes
    mapping(bytes32 => Inode) internal inodes;

    // Instance of the ContentStore contract
    ContentStore public contentStore;

    constructor(address _contentStore) {
        contentStore = ContentStore(_contentStore);
    }

    // Function to create a file
    function createFile(bytes memory metadata, bytes32[] memory chunkPointers) public {
        bytes32 checksum = keccak256(
            abi.encode(keccak256(abi.encode(chunkPointers)), keccak256(abi.encode(metadata)), bytes1(0x01))
        );
        require(!inodeExists(checksum), "Inode already exists");

        File memory newFile = File(metadata, chunkPointers);
        inodes[checksum] = Inode(InodeType.File, newFile, Directory(new string[](0), new bytes32[](0)));
    }

    // Function to create a directory
    function createDirectory(string[] memory names, bytes32[] memory inodePointers) public {
        require(names.length == inodePointers.length, "Mismatch in lengths of names and inodePointers");

        bytes32 checksum = keccak256(abi.encode(names, inodePointers, bytes1(0x00)));
        require(!inodeExists(checksum), "Inode already exists");

        Directory memory newDirectory = Directory(names, inodePointers);
        inodes[checksum] = Inode(InodeType.Directory, File("", new bytes32[](0)), newDirectory);
    }

    // Function to check if an inode exists
    function inodeExists(bytes32 checksum) public view returns (bool) {
        // In Solidity, an uninitialized struct has all its fields set to their default values
        // So, we can check if a file or directory exists by checking if both its fields are default
        Inode memory inode = inodes[checksum];
        return
            inode.inodeType == InodeType.File ||
            (inode.file.metadata.length != 0 || inode.file.chunkPointers.length != 0);
    }
}
