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
    address public immutable CONTENT_STORE;

    /**
     * @dev Mapping of checksum pointer to Inode struct
     */
    mapping(bytes32 checksum => Inode inode) internal inodes;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the ContentStore contract
     */
    constructor(address _contentStore) {
        CONTENT_STORE = _contentStore;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFileSystem
     */
    function createDirectory(
        string[] calldata _paths,
        bytes32[] calldata _fileChecksums
    ) external returns (bytes32 directoryChecksum) {
        if (_paths.length != _fileChecksums.length) revert LengthMismatch();
        bytes32[] memory hashedPaths = hashPaths(_paths);
        directoryChecksum = keccak256(
            bytes.concat(
                METADATA_TYPE,
                keccak256(abi.encodePacked(hashedPaths)),
                keccak256(abi.encodePacked(_fileChecksums))
            )
        );
        if (inodeExists(directoryChecksum)) revert InodeAlreadyExists();
        Directory memory newDirectory = Directory(_paths, _fileChecksums);
        inodes[directoryChecksum] = Inode(InodeType.Directory, File(bytes(""), new bytes32[](0)), newDirectory);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function createFile(
        bytes calldata _filename,
        bytes32[] calldata _chunkChecksums
    ) external returns (bytes32 fileChecksum) {
        if (_containsForbiddenChars(string(_filename))) revert InvalidCharacter();
        fileChecksum = keccak256(
            bytes.concat(METADATA_TYPE, keccak256(abi.encodePacked(_chunkChecksums)), keccak256(_filename))
        );
        if (inodeExists(fileChecksum)) revert InodeAlreadyExists();
        File memory newFile = File(_filename, _chunkChecksums);
        inodes[fileChecksum] = Inode(InodeType.File, newFile, Directory(new string[](0), new bytes32[](0)));
    }

    /**
     * @inheritdoc IFileSystem
     */
    function readDirectory(bytes32 _checksum) external view returns (string[] memory, bytes32[] memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType != InodeType.Directory) revert DirectoryNotFound();
        return (inode.directory.fileNames, inode.directory.filePointers);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function readFile(bytes32 _checksum) external view returns (bytes memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType != InodeType.File) revert FileNotFound();
        return concatenateChunks(inode.file.chunkPointers);
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
            pointer = IContentStore(CONTENT_STORE).getPointer(_pointers[i]);
            chunkContent = SSTORE2.read(pointer);
            fileContent = abi.encodePacked(fileContent, chunkContent);
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function hashPaths(string[] calldata _paths) public pure returns (bytes32[] memory hashedPaths) {
        uint256 length = _paths.length;
        hashedPaths = new bytes32[](length);
        for (uint256 i; i < length; i++) {
            if (_containsForbiddenChars(_paths[i])) revert InvalidCharacter();
            hashedPaths[i] = keccak256(bytes(_paths[i]));
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function inodeExists(bytes32 _checksum) public view returns (bool) {
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType == InodeType.File) {
            File memory file = inode.file;
            return file.metadata.length != 0 || file.chunkPointers.length != 0;
        } else {
            Directory memory directory = inode.directory;
            return directory.fileNames.length != 0 || directory.filePointers.length != 0;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Checks if the given string contains any forbidden characters
     */
    function _containsForbiddenChars(string calldata _stringToCheck) private pure returns (bool) {
        uint256 length = bytes(_stringToCheck).length;
        for (uint256 i; i < length; i++) {
            for (uint256 j; j < CHARACTER_LENGTH; j++) {
                if (bytes(_stringToCheck)[i] == bytes(FORBIDDEN_CHARS)[j]) {
                    return true;
                }
            }
        }
        return false;
    }
}
