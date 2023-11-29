// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "src/utils/Constants.sol";

import {ContentStore} from "ethfs/packages/contracts/src/ContentStore.sol";
import {FileSystem, InodeType} from "src/FileSystem.sol";
import {BytesLib} from "test/utils/BytesLib.sol";

import {IContentStore} from "ethfs/packages/contracts/src/IContentStore.sol";
import {IFileSystem} from "src/interfaces/IFileSystem.sol";

contract FileSystemTest is Test {
    // Contracts
    FileSystem internal fileSystem;

    // State
    address internal contentStore;
    bytes32 internal checksum;
    bytes32[] internal filePointers;
    string[] internal fileNames;

    // Errors
    bytes4 internal immutable CHUNK_NOT_FOUND_ERROR = IFileSystem.ChunkNotFound.selector;
    bytes4 internal immutable DIRECTORY_NOT_FOUND_ERROR = IFileSystem.DirectoryNotFound.selector;
    bytes4 internal immutable FILE_NOT_FOUND_ERROR = IFileSystem.FileNotFound.selector;
    bytes4 internal immutable INODE_ALREADY_EXISTS_ERROR = IFileSystem.InodeAlreadyExists.selector;
    bytes4 internal immutable INODE_NOT_FOUND_ERROR = IFileSystem.InodeNotFound.selector;
    bytes4 internal immutable INVALID_CHARACTER_ERROR = IFileSystem.InvalidCharacter.selector;
    bytes4 internal immutable LENGTH_MISMATCH_ERROR = IFileSystem.LengthMismatch.selector;

    function setUp() public virtual {
        contentStore = address(new ContentStore());
        fileSystem = new FileSystem(address(contentStore));
    }
}
