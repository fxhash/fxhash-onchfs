// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IContentStore} from "ethfs/packages/contracts/src/IContentStore.sol";
import {SSTORE2} from "sstore2/SSTORE2.sol";

contract INodeStore {
    struct File {
        bytes metadata;
        bytes32[] chunkPointers;
    }

    struct Directory {
        string[] names;
        bytes32[] fileInodePointers;
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

    mapping(bytes32 checksum => Inode inode) internal inodes;

    IContentStore public contentStore;

    /// @dev Thrown when an invalid character is present in a string
    error ForbiddenCharacter();
    /// @dev Thrown when attemping to create an inode and the checksum is already associated with an inode
    error InodeAlreadyExists();
    /// @dev Thrown when attempting to read an inode that doesn't exist
    error InodeNotFound();
    /// @dev Thrown when attempting to read a file that doesn't exist
    error FileNotFound();
    /// @dev Thrown when reading a directory that doesn't exists
    error DirectoryNotFound();
    /// @dev Thrown when an invalid character is present in a string
    error InodeMismatch();

    constructor(address _contentStore) {
        contentStore = IContentStore(_contentStore);
    }

    /**
     * @dev Creates a new file with the given metadata and chunk pointers
     * @param _metadata The metadata of the file
     * @param _chunkPointers The pointers to the file chunks
     */
    function createFile(bytes memory _metadata, bytes32[] memory _chunkPointers) external {
        if (containsForbiddenCharacters(string(_metadata), FORBIDDEN_CHARS)) revert ForbiddenCharacter();
        bytes32 checksum = keccak256(
            bytes.concat(bytes1(0x01), keccak256(abi.encodePacked(_chunkPointers)), keccak256(_metadata))
        );
        if (inodeExists(checksum)) revert InodeAlreadyExists();
        File memory newFile = File(_metadata, _chunkPointers);
        inodes[checksum] = Inode(InodeType.File, newFile, Directory(new string[](0), new bytes32[](0)));
    }

    /**
     * @dev Creates a new directory with the given names and file inode pointers
     * @param _names The names of the files in the directory
     * @param _fileInodePointers The pointers to the file inodes in the directory
     */
    function createDirectory(string[] memory _names, bytes32[] memory _fileInodePointers) external {
        if (_names.length != _fileInodePointers.length) revert InodeMismatch();
        bytes32[] memory hashedNames = hashNames(_names);

        bytes32 checksum = keccak256(
            bytes.concat(
                bytes1(0x00),
                keccak256(abi.encodePacked(hashedNames)),
                keccak256(abi.encodePacked(_fileInodePointers))
            )
        );
        if (inodeExists(checksum)) revert InodeAlreadyExists();
        Directory memory newDirectory = Directory(_names, _fileInodePointers);
        inodes[checksum] = Inode(InodeType.Directory, File("", new bytes32[](0)), newDirectory);
    }

    /**
     * @dev Reads the content of a file with the given checksum
     * @param _checksum The checksum of the file
     * @return The content of the file
     */
    function readFile(bytes32 _checksum) external view returns (bytes memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType != InodeType.File) revert FileNotFound();
        return concatenateChunksFromPointers(inode.file.chunkPointers);
    }

    /**
     * @dev Reads the content of a directory with the given checksum
     * @param _checksum The checksum of the directory
     * @return The names and file inode pointers in the directory
     */
    function readDirectory(bytes32 _checksum) external view returns (string[] memory, bytes32[] memory) {
        if (!inodeExists(_checksum)) revert InodeNotFound();
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType != InodeType.Directory) revert DirectoryNotFound();
        return (inode.directory.names, inode.directory.fileInodePointers);
    }

    /**
     * @dev Checks if an inode with the given checksum exists
     * @param _checksum The checksum of the inode
     * @return True if the inode exists, false otherwise
     */
    function inodeExists(bytes32 _checksum) public view returns (bool) {
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType == InodeType.File) {
            return inode.file.metadata.length != 0 || inode.file.chunkPointers.length != 0;
        } else {
            return inode.directory.names.length != 0 || inode.directory.fileInodePointers.length != 0;
        }
    }

    /**
     * @dev Concatenates the content of file chunks from the given pointers
     * @param _fileChunkPointers The pointers to the file chunks
     * @return The concatenated content of the file chunks
     */
    function concatenateChunksFromPointers(bytes32[] memory _fileChunkPointers) private view returns (bytes memory) {
        bytes memory fileContent;
        for (uint256 i = 0; i < _fileChunkPointers.length; i++) {
            bytes32 chunkChecksum = _fileChunkPointers[i];
            address pointer = contentStore.getPointer(chunkChecksum);
            bytes memory chunkContent = SSTORE2.read(pointer);
            fileContent = abi.encodePacked(fileContent, chunkContent);
        }
        return fileContent;
    }

    /**
     * @dev Checks if the given string contains any forbidden characters
     * @param _string The string to check
     * @param _characters The forbidden characters
     * @return True if the string contains forbidden characters, false otherwise
     */
    function containsForbiddenCharacters(string memory _string, string memory _characters) private pure returns (bool) {
        for (uint256 i = 0; i < bytes(_string).length; i++) {
            for (uint256 j = 0; j < bytes(_characters).length; j++) {
                if (bytes(_string)[i] == bytes(_characters)[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @dev Hashes the names of the files in the directory
     * @param _names The names of the files
     * @return The hashed names
     */
    function hashNames(string[] memory _names) private pure returns (bytes32[] memory) {
        uint256 length = _names.length;
        bytes32[] memory hashedNames = new bytes32[](length);
        for (uint256 i; i < length; i++) {
            if (containsForbiddenCharacters(_names[i], FORBIDDEN_CHARS)) revert ForbiddenCharacter();
            hashedNames[i] = keccak256(bytes(_names[i]));
        }
        return hashedNames;
    }
}
