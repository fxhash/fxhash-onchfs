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
     * @dev Mapping of checksum to inode struct
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
    function createFile(bytes memory _metadata, bytes32[] memory _chunkPointers) external {
        if (_containsForbiddenCharacters(string(_metadata), FORBIDDEN_CHARS)) revert InvalidCharacter();
        bytes32 checksum = keccak256(
            bytes.concat(METADATA_TYPE, keccak256(abi.encodePacked(_chunkPointers)), keccak256(_metadata))
        );
        if (inodeExists(checksum)) revert InodeAlreadyExists();
        File memory newFile = File(_metadata, _chunkPointers);
        inodes_[checksum] = Inode(InodeType.File, newFile, Directory(new string[](0), new bytes32[](0)));
    }

    /**
     * @inheritdoc IFileSystem
     */
    function createDirectory(string[] memory _names, bytes32[] memory _filePointers) external {
        if (_names.length != _filePointers.length) revert LengthMismatch();
        bytes32[] memory hashedNames = hashNames(_names);
        bytes32 checksum = keccak256(
            bytes.concat(
                METADATA_TYPE,
                keccak256(abi.encodePacked(hashedNames)),
                keccak256(abi.encodePacked(_filePointers))
            )
        );
        if (inodeExists(checksum)) revert InodeAlreadyExists();
        Directory memory newDirectory = Directory(_names, _filePointers);
        inodes_[checksum] = Inode(InodeType.Directory, File("", new bytes32[](0)), newDirectory);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function readDirectory(bytes32 _checksum) external view returns (string[] memory, bytes32[] memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes_[_checksum];
        if (inode.inodeType != InodeType.Directory) revert DirectoryNotFound();
        return (inode.directory.names, inode.directory.fileInodePointers);
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
    function hashNames(string[] memory _names) public pure returns (bytes32[] memory hashedNames) {
        uint256 length = _names.length;
        hashedNames = new bytes32[](length);
        for (uint256 i; i < length; i++) {
            if (_containsForbiddenCharacters(_names[i], FORBIDDEN_CHARS)) revert InvalidCharacter();
            hashedNames[i] = keccak256(bytes(_names[i]));
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function inodeExists(bytes32 _checksum) public view returns (bool) {
        Inode memory inode = inodes_[_checksum];
        if (inode.inodeType == InodeType.File) {
            return inode.file.metadata.length != 0 || inode.file.chunkPointers.length != 0;
        } else {
            return inode.directory.names.length != 0 || inode.directory.fileInodePointers.length != 0;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Checks if the given string contains any forbidden characters
     */
    function _containsForbiddenCharacters(
        string memory _checkedChars,
        string memory _forbiddenChars
    ) private pure returns (bool) {
        uint256 checkedCharsLen = bytes(_checkedChars).length;
        uint256 forbiddenCharsLen = bytes(_forbiddenChars).length;
        for (uint256 i; i < checkedCharsLen; i++) {
            for (uint256 j; j < forbiddenCharsLen; j++) {
                if (bytes(_checkedChars)[i] == bytes(_forbiddenChars)[j]) {
                    return true;
                }
            }
        }
        return false;
    }
}
