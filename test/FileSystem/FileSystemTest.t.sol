// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "script/utils/Constants.sol";
import "src/utils/Constants.sol";
import "test/utils/Constants.sol";

import {BytesLib} from "test/lib/BytesLib.sol";
import {ContentStore} from "ethfs/packages/contracts/src/ContentStore.sol";
import {FileSystem} from "src/FileSystem.sol";

import {IContentStore} from "ethfs/packages/contracts/src/IContentStore.sol";
import {IFileSystem, InodeType} from "src/interfaces/IFileSystem.sol";

contract FileSystemTest is Test {
    // Contracts
    FileSystem internal fileSystem;

    // State
    address internal contentStore;
    bytes internal fileContent;
    bytes internal hashedFiles;
    bytes internal metadata;
    bytes32 internal checksum;
    bytes32 internal fileChecksum;
    bytes32[] internal chunkChecksums;
    bytes32[] internal filePointers;
    string[] internal fileNames;

    // Errors
    bytes4 internal immutable CHUNK_NOT_FOUND_ERROR = IFileSystem.ChunkNotFound.selector;
    bytes4 internal immutable DIRECTORY_NOT_FOUND_ERROR = IFileSystem.DirectoryNotFound.selector;
    bytes4 internal immutable FILE_NOT_FOUND_ERROR = IFileSystem.FileNotFound.selector;
    bytes4 internal immutable INODE_NOT_FOUND_ERROR = IFileSystem.InodeNotFound.selector;
    bytes4 internal immutable INVALID_CHARACTER_ERROR = IFileSystem.InvalidCharacter.selector;
    bytes4 internal immutable INVALID_FILENAME_ERROR = IFileSystem.InvalidFileName.selector;
    bytes4 internal immutable LENGTH_MISMATCH_ERROR = IFileSystem.LengthMismatch.selector;

    function setUp() public virtual {
        contentStore = GOERLI_CONTENT_STORE;
        vm.etch(contentStore, CONTENT_STORE_BYTE_CODE);
        fileSystem = new FileSystem(contentStore);
        metadata = "file metadata";
        fileContent = bytes("asdf");
        (checksum, ) = IContentStore(contentStore).addContent(fileContent);
        chunkChecksums.push(checksum);
    }
}
