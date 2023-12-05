// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/*//////////////////////////////////////////////////////////////////////////
                                STRUCTS
//////////////////////////////////////////////////////////////////////////*/

/**
 * @notice Type of inode
 * - `Directory` List of inodes with their assigned names
 * - `File` Single inode with assigned name
 */
enum InodeType {
    Directory,
    File
}

/**
 * @notice Struct of directory information
 * - `filenames` List of filenames
 * - `fileChecksums` List of checksums for each file
 */
struct Directory {
    string[] filenames;
    bytes32[] fileChecksums;
}

/**
 * @notice Struct of file information
 * - `metadata` Bytes-encoded metadata of file
 * - `chunkChecksums` List of chunked checksums
 */
struct File {
    bytes metadata;
    bytes32[] chunkChecksums;
}

/**
 * @notice Struct of inode information
 * - `inodeType` Type of inode
 * - `file` Struct of file information
 * - `directory` Struct of directory information
 */
struct Inode {
    InodeType inodeType;
    File file;
    Directory directory;
}
