// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/*//////////////////////////////////////////////////////////////////////////
                                STRUCTS
//////////////////////////////////////////////////////////////////////////*/

enum InodeType {
    Directory,
    File
}

struct Directory {
    string[] filenames;
    bytes32[] fileChecksums;
}

struct File {
    bytes metadata;
    bytes32[] chunkChecksums;
}

struct Inode {
    InodeType inodeType;
    File file;
    Directory directory;
}
