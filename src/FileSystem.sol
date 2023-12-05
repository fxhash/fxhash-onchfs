// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SSTORE2} from "sstore2/SSTORE2.sol";

import {IContentStore} from "ethfs/packages/contracts/src/IContentStore.sol";
import {IFileSystem, Directory, File, Inode, InodeType} from "src/interfaces/IFileSystem.sol";

import "src/utils/Constants.sol";

/**
 * @title FileSystem
 * @author fx(hash)
 * @notice See the documentation in {IFileSystem}
 */
contract FileSystem is IFileSystem {
    /*//////////////////////////////////////////////////////////////////////////
                                    STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFileSystem
     */
    address public immutable contentStore;

    /**
     * @inheritdoc IFileSystem
     */
    mapping(bytes32 checksum => Inode inode) public inodes;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the ContentStore contract
     */
    constructor(address _contentStore) {
        contentStore = _contentStore;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFileSystem
     */
    function createDirectory(
        string[] calldata _fileNames,
        bytes32[] calldata _inodeChecksums
    ) external returns (bytes32 directoryChecksum) {
        if (_fileNames.length != _inodeChecksums.length) revert LengthMismatch();
        bytes memory concatenatedFiles = concatenateFiles(_fileNames, _inodeChecksums);

        for (uint256 i; i < _inodeChecksums.length; i++) {
            if (!inodeExists(_inodeChecksums[i])) revert InodeNotFound();
        }
        directoryChecksum = keccak256(bytes.concat(bytes1(uint8(InodeType.Directory)), concatenatedFiles));
        if (inodeExists(directoryChecksum)) return directoryChecksum;
        inodes[directoryChecksum].directory = Directory(_fileNames, _inodeChecksums);
        emit DirectoryCreated(directoryChecksum, _fileNames, _inodeChecksums);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function createFile(
        bytes calldata _metadata,
        bytes32[] calldata _chunkPointers
    ) external returns (bytes32 fileChecksum) {
        for (uint256 i; i < _chunkPointers.length; i++) {
            if (!IContentStore(contentStore).checksumExists(_chunkPointers[i])) revert ChunkNotFound();
        }
        fileChecksum = keccak256(
            bytes.concat(
                bytes1(uint8(InodeType.File)),
                keccak256(abi.encodePacked(_chunkPointers)),
                keccak256(_metadata)
            )
        );
        if (inodeExists(fileChecksum)) return fileChecksum;
        inodes[fileChecksum].inodeType = InodeType.File;
        inodes[fileChecksum].file = File(_metadata, _chunkPointers);
        emit FileCreated(fileChecksum, _metadata, _chunkPointers);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function readDirectory(bytes32 _checksum) external view returns (string[] memory, bytes32[] memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType != InodeType.Directory) revert DirectoryNotFound();
        return (inode.directory.filenames, inode.directory.fileChecksums);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function readFile(bytes32 _checksum) external view returns (bytes memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType != InodeType.File) revert FileNotFound();
        return concatenateChunks(inode.file.chunkChecksums);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFileSystem
     */
    function concatenateChunks(bytes32[] memory _pointers) public view returns (bytes memory fileContent) {
        address pointer;
        bytes memory chunkContent;
        for (uint256 i; i < _pointers.length; i++) {
            pointer = IContentStore(contentStore).getPointer(_pointers[i]);
            chunkContent = SSTORE2.read(pointer);
            fileContent = abi.encodePacked(fileContent, chunkContent);
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function concatenateFiles(
        string[] calldata _fileNames,
        bytes32[] calldata _filePointers
    ) public pure returns (bytes memory concatenatedFiles) {
        uint256 length = _fileNames.length;
        bytes memory filename;
        for (uint256 i; i < length; i++) {
            filename = bytes(_fileNames[i]);
            if (filename.length == 0) revert InvalidFileName();
            if (_containsForbiddenChars(filename)) revert InvalidCharacter();
            concatenatedFiles = abi.encodePacked(_filePointers[i], keccak256(filename), concatenatedFiles);
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function getInodeAt(
        bytes32 _inodeChecksum,
        string[] memory _pathSegments
    ) public view returns (bytes32 inodeChecksum, Inode memory inode) {
        if (!inodeExists(_inodeChecksum)) revert InodeNotFound();
        inode = inodes[_inodeChecksum];
        inodeChecksum = _inodeChecksum;
        uint256 length = _pathSegments.length;
        Directory memory directory;
        string[] memory filenames;
        bool found;
        for (uint256 i; i < length; i++) {
            if (inode.inodeType != InodeType.Directory) revert InodeNotFound();
            directory = inode.directory;
            filenames = inode.directory.filenames;
            found = false;
            for (uint256 j; j < filenames.length; j++) {
                if (keccak256(bytes(filenames[j])) == keccak256(bytes(_pathSegments[i]))) {
                    found = true;
                    inodeChecksum = directory.fileChecksums[j];
                    inode = inodes[inodeChecksum];
                    break;
                }
            }
            if (!found) revert InodeNotFound();
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function inodeExists(bytes32 _checksum) public view returns (bool) {
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType == InodeType.File) {
            return inode.file.metadata.length != 0 || inode.file.chunkChecksums.length != 0;
        } else {
            return inode.directory.filenames.length != 0 || inode.directory.fileChecksums.length != 0;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Checks if the given string contains any forbidden characters
     */
    function _containsForbiddenChars(bytes memory _string) private pure returns (bool) {
        uint256 length = _string.length;
        for (uint256 i; i < length; i++) {
            for (uint256 j; j < FORBIDDEN_CHARS.length; j++) {
                if (_string[i] == FORBIDDEN_CHARS[j]) {
                    return true;
                }
            }
        }
        return false;
    }
}
