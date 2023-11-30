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
        CONTENT_STORE = _contentStore;
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
        bytes32[] memory hashedFiles = hashFiles(_fileNames, _inodeChecksums);

        for (uint256 i; i < _inodeChecksums.length; i++) {
            if (!inodeExists(_inodeChecksums[i])) revert InodeNotFound();
        }
        directoryChecksum = keccak256(
            bytes.concat(bytes1(uint8(InodeType.Directory)), keccak256(abi.encodePacked(hashedFiles)))
        );
        if (inodeExists(directoryChecksum)) return directoryChecksum;
        inodes[directoryChecksum].directory = Directory(_fileNames, _inodeChecksums);
    }

    /**
     * @inheritdoc IFileSystem
     */
    function createFile(
        bytes calldata _metadata,
        bytes32[] calldata _chunkPointers
    ) external returns (bytes32 fileChecksum) {
        for (uint256 i; i < _chunkPointers.length; i++) {
            if (!IContentStore(CONTENT_STORE).checksumExists(_chunkPointers[i])) revert ChunkNotFound();
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
            pointer = IContentStore(CONTENT_STORE).getPointer(_pointers[i]);
            chunkContent = SSTORE2.read(pointer);
            fileContent = abi.encodePacked(fileContent, chunkContent);
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function hashFiles(
        string[] calldata _fileNames,
        bytes32[] calldata _filePointers
    ) public pure returns (bytes32[] memory hashedFiles) {
        uint256 length = _fileNames.length;
        hashedFiles = new bytes32[](length);
        bytes memory filename;
        for (uint256 i; i < length; i++) {
            filename = bytes(_fileNames[i]);
            if (filename.length == 0) revert InvalidFileName();
            if (_containsForbiddenChars(filename)) revert InvalidCharacter();
            hashedFiles[i] = keccak256(bytes.concat(keccak256(filename), keccak256(bytes.concat(_filePointers[i]))));
        }
    }

    /**
     * @inheritdoc IFileSystem
     */
    function inodeExists(bytes32 _checksum) public view returns (bool) {
        Inode memory inode = inodes[_checksum];
        if (inode.inodeType == InodeType.File) {
            return inode.file.chunkChecksums.length != 0;
        } else {
            return inode.directory.fileChecksums.length != 0;
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

    function getInodeAt(
        bytes32 _inodeChecksum,
        string[] memory _pathSegments
    ) public view returns (bytes32 inodeChecksum) {
        if (!inodeExists(_inodeChecksum)) revert InodeNotFound();

        Inode memory inode = inodes[_inodeChecksum];
        bytes32 inodeChecksum = _inodeChecksum;
    
        uint256 length = _pathSegments.length;
        Directory memory directory;
        string memory filenames;
        bool found;
        
        for (uint256 i; i < length; i++) {
            if (inode.inodeType != InodeType.Directory) revert InodeNotFound();
            directory = inode.directory;
            filenames = inode.directory.filenames;
            found = false;
            for (uint256 j; j < filenames.length; j++) {
                if (filenames[j] == _pathSegments[i]) {
                    found = true;
                    inodeChecksum = directory.fileChecksums[i]
                    inode = inodes[inodeChecksum]
                    break
                }
            }
            if (!found) revert InodeNotFound();
        }

        // better format here
        return (
            inodeChecksum,
            inode
        )
    }
    //
    // @sp.onchain_view()
    // def get_inode_at(self, uri):
    //   sp.set_type(uri, sp.TRecord(
    //     cid = sp.TBytes,
    //     path = sp.TList(sp.TString),
    //   ))
    //   sp.verify(self.data.inodes.contains(uri.cid), Errors.INODE_NOT_FOUND)
    //   # Set base inode to be the one under uri.cid
    //   inode = sp.local("inode", self.data.inodes[uri.cid])
    //   cid = sp.local("cid", uri.cid)
    //   # Loop through each segment in the path to navigate the tree of files
    //   # recursively starting from base node
    //   sp.for segment in uri.path:
    //     sp.verify(inode.value.is_variant("directory"), Errors.INODE_NOT_FOUND)
    //     opened = inode.value.open_variant("directory")
    //     sp.verify(opened.contains(segment), Errors.INODE_NOT_FOUND)
    //     cid.value = opened[segment]
    //     inode.value = self.data.inodes[cid.value]
    //   sp.result(sp.record(
    //     cid = cid.value,
    //     inode = inode.value,
    //   ))
}
