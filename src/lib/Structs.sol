// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/*//////////////////////////////////////////////////////////////////////////
                                STRUCTS
//////////////////////////////////////////////////////////////////////////*/

enum InodeType {
    File,
    Directory
}

struct Directory {
    string[] fileNames;
    bytes32[] filePointers;
}

struct File {
    bytes metadata;
    bytes32[] chunkPointers;
}

struct Inode {
    InodeType inodeType;
    File file;
    Directory directory;
}
