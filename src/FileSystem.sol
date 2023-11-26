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
     * @dev Mapping of checksum pointer to Inode struct
     */
    mapping(bytes32 checksum => Inode inode) internal inodes_;

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
    function createDirectory(string[] calldata _fileNames, bytes32[] calldata _filePointers) external {
        if (_fileNames.length != _filePointers.length) revert LengthMismatch();
        bytes32[] memory hashedNames = hashNames(_fileNames);
        bytes32 checksum = keccak256(
            bytes.concat(
                DIRECTORY_TYPE,
                keccak256(abi.encodePacked(hashedNames)),
                keccak256(abi.encodePacked(_filePointers))
            )
        );
        if (inodeExists(checksum)) revert InodeAlreadyExists();
        Directory memory newDirectory = Directory(_fileNames, _filePointers);
        inodes_[checksum] = Inode(InodeType.Directory, File(bytes(""), new bytes32[](0)), newDirectory);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function createFile(bytes calldata _metadata, bytes32[] calldata _chunkPointers) external {
        if (_containsForbiddenChars(string(_metadata))) revert InvalidCharacter();
        bytes32 checksum = keccak256(
            bytes.concat(FILE_TYPE, keccak256(abi.encodePacked(_chunkPointers)), keccak256(_metadata))
        );
        if (inodeExists(checksum)) revert InodeAlreadyExists();
        File memory newFile = File(_metadata, _chunkPointers);
        inodes_[checksum] = Inode(InodeType.File, newFile, Directory(new string[](0), new bytes32[](0)));
    }

    /**
     * @inheritdoc IFileSystem
     */
    function readDirectory(bytes32 _checksum) external view returns (string[] memory, bytes32[] memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes_[_checksum];
        if (inode.inodeType != InodeType.Directory) revert DirectoryNotFound();
        return (inode.directory.fileNames, inode.directory.filePointers);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function readFile(bytes32 _checksum) external view returns (bytes memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes_[_checksum];
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
            pointer = IContentStore(contentStore).getPointer(_pointers[i]);
            chunkContent = SSTORE2.read(pointer);
            fileContent = abi.encodePacked(fileContent, chunkContent);
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function hashNames(string[] calldata _fileNames) public pure returns (bytes32[] memory hashedNames) {
        uint256 length = _fileNames.length;
        hashedNames = new bytes32[](length);
        for (uint256 i; i < length; i++) {
            if (_containsForbiddenChars(_fileNames[i])) revert InvalidCharacter();
            hashedNames[i] = keccak256(bytes(_fileNames[i]));
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function inodeExists(bytes32 _checksum) public view returns (bool) {
        Inode memory inode = inodes_[_checksum];
        File memory file = inode.file;
        Directory memory directory = inode.directory;
        if (inode.inodeType == InodeType.File) {
            return file.metadata.length != 0 || file.chunkPointers.length != 0;
        } else {
            return directory.fileNames.length != 0 || directory.filePointers.length != 0;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Checks if the given string contains any forbidden characters
     */
    function _containsForbiddenChars(string calldata _characters) private pure returns (bool) {
        uint256 length = bytes(_characters).length;
        for (uint256 i; i < length; i++) {
            for (uint256 j; j < CHARACTER_LEGNTH; j++) {
                if (bytes(_characters)[i] == bytes(FORBIDDEN_CHARS)[j]) {
                    return true;
                }
            }
        }
        return false;
    }
}
