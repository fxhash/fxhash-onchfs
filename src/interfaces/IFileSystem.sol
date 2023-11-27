// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Directory, File, Inode, InodeType} from "src/lib/Structs.sol";

/**
 * @title IFileSystem
 * @author fx(hash)
 * @notice System for storing and retrieving files onchain
 */
interface IFileSystem {
    /*//////////////////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Error thrown when reading a directory that does not exist
     */
    error DirectoryNotFound();

    /**
     * @notice Error thrown when attempting to read a file that does not exist
     */
    error FileNotFound();

    /**
     * @notice Error thrown when the checksum is already associated with an inode
     */
    error InodeAlreadyExists();

    /**
     * @notice Error thrown when attempting to read an inode that does not exist
     */
    error InodeNotFound();

    /**
     * @notice Error thrown when a forbidden character is present
     */
    error InvalidCharacter();

    /**
     * @notice Error thrown when array lengths do not match
     */
    error LengthMismatch();

    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Concatenates the content of file chunks from the given pointers
     * @param _chunkChecksums Checksums for the file chunks
     * @return Concatenated content of the file chunks
     */
    function concatenateChunks(bytes32[] memory _chunkChecksums) external view returns (bytes memory);

    /**
     * @notice Returns the address of the ContentStore contract
     */
    function CONTENT_STORE() external view returns (address);

    /**
     * @notice Creates a new directory with the given names and file inode pointers
     * @param _paths List of file paths in the directory
     * @param _fileChecksums Pointers to the file inodes in the directory
     */
    function createDirectory(
        string[] calldata _paths,
        bytes32[] calldata _fileChecksums
    ) external returns (bytes32 directoryChecksum);

    /**
     * @notice Creates a new file with the given metadata and chunk pointers
     * @param _filename Metadata of the file
     * @param _chunkChecksums Checksums for chunks of the file
     */
    function createFile(
        bytes calldata _filename,
        bytes32[] calldata _chunkChecksums
    ) external returns (bytes32 fileChecksum);

    /**
     * @notice Hashes a list of file names in the directory
     * @param _paths List of file names
     * @return Hashed names
     */
    function hashPaths(string[] calldata _paths) external view returns (bytes32[] memory);

    /**
     *
     */
    function inodes(bytes32 _checksum) external view returns (InodeType, File memory, Directory memory);

    /**
     * @notice Reads the content of a directory with the given checksum
     * @param _checksum Checksum of the directory
     * @return Names and file inode pointers in the directory
     */
    function readDirectory(bytes32 _checksum) external view returns (string[] memory, bytes32[] memory);

    /**
     * @notice Reads the content of a file with the given checksum
     * @param _checksum Checksum of the file
     * @return Content of the file
     */
    function readFile(bytes32 _checksum) external view returns (bytes memory);

    /**
     * @notice Checks if an inode with the given checksum exists
     * @param _checksum Checksum of the inode
     * @return Status of inode existence
     */
    function inodeExists(bytes32 _checksum) external view returns (bool);
}
