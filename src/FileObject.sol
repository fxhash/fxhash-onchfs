// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ContentStore} from "ethfs/packages/contracts/src/ContentStore.sol";
import {SSTORE2} from "sstore2/SSTORE2.sol";

contract FileObject {
    struct File {
        bytes metadata;
        bytes32[] chunkPointers;
    }

    struct Directory {
        string[] names;
        bytes32[] inodePointers;
    }

    enum InodeType {
        File,
        Directory
    }

    struct Inode {
        InodeType inodeType;
        File file;
        Directory directory;
    }

    string private constant FORBIDDEN_CHARS = ":/?#[]@!$&'()*+,;=";

    mapping(bytes32 => Inode) internal inodes;
    ContentStore public contentStore;

    // Custom errors
    error ForbiddenCharacter();
    error InodeAlreadyExists();
    error InodeNotFound();
    error InodeMismatch();

    constructor(address _contentStore) {
        contentStore = ContentStore(_contentStore);
    }

    function createFile(bytes memory metadata, bytes32[] memory chunkPointers) public {
        if (verifyNotIncludes(string(metadata), FORBIDDEN_CHARS)) revert ForbiddenCharacter();
        bytes32 checksum = keccak256(
            bytes.concat(bytes1(0x01), keccak256(abi.encodePacked(chunkPointers)), keccak256(metadata))
        );
        if (inodeExists(checksum)) revert InodeAlreadyExists();
        File memory newFile = File(metadata, chunkPointers);
        inodes[checksum] = Inode(InodeType.File, newFile, Directory(new string[](0), new bytes32[](0)));
    }

    function createDirectory(string[] memory names, bytes32[] memory inodePointers) public {
        if (names.length != inodePointers.length) revert InodeMismatch();
        bytes32[] memory hashedNames = hashNames(names);

        bytes32 checksum = keccak256(
            bytes.concat(
                bytes1(0x00),
                keccak256(abi.encodePacked(hashedNames)),
                keccak256(abi.encodePacked(inodePointers))
            )
        );
        if (inodeExists(checksum)) revert InodeAlreadyExists();
        Directory memory newDirectory = Directory(names, inodePointers);
        inodes[checksum] = Inode(InodeType.Directory, File("", new bytes32[](0)), newDirectory);
    }

    function readFile(bytes32 checksum) public view returns (bytes memory) {
        if (!inodeExists(checksum)) revert InodeNotFound();
        Inode memory inode = inodes[checksum];
        if (inode.inodeType != InodeType.File) revert InodeNotFound();
        return concatenateChunks(inode.file.chunkPointers);
    }

    function readDirectory(bytes32 checksum) public view returns (string[] memory, bytes32[] memory) {
        if (!inodeExists(checksum)) revert InodeNotFound();
        Inode memory inode = inodes[checksum];
        if (inode.inodeType != InodeType.Directory) revert InodeNotFound();
        return (inode.directory.names, inode.directory.inodePointers);
    }

    function inodeExists(bytes32 checksum) public view returns (bool) {
        Inode memory inode = inodes[checksum];
        if (inode.inodeType == InodeType.File) {
            return inode.file.metadata.length != 0 || inode.file.chunkPointers.length != 0;
        } else {
            return inode.directory.names.length != 0 || inode.directory.inodePointers.length != 0;
        }
    }

    function verifyNotIncludes(string memory str, string memory charset) private pure returns (bool) {
        for (uint256 i = 0; i < bytes(str).length; i++) {
            for (uint256 j = 0; j < bytes(charset).length; j++) {
                if (bytes(str)[i] == bytes(charset)[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function hashNames(string[] memory names) private pure returns (bytes32[] memory) {
        uint256 length = names.length;
        bytes32[] memory hashedNames = new bytes32[](length);
        for (uint256 i; i < length; i++) {
            if (!verifyNotIncludes(names[i], FORBIDDEN_CHARS)) revert ForbiddenCharacter();
            hashedNames[i] = keccak256(bytes(names[i]));
        }
        return hashedNames;
    }

    function concatenateChunks(bytes32[] memory chunkPointers) private view returns (bytes memory) {
        bytes memory fileContent;
        for (uint256 i = 0; i < chunkPointers.length; i++) {
            bytes32 chunkChecksum = chunkPointers[i];
            address pointer = contentStore.getPointer(chunkChecksum);
            bytes memory chunkContent = SSTORE2.read(pointer);
            fileContent = abi.encodePacked(fileContent, chunkContent);
        }
        return fileContent;
    }
}
