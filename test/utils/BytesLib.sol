// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library BytesLib {
    function generateRandomBytes(uint256 amount) public view returns (bytes memory) {
        bytes memory randomBytes = new bytes(amount);
        uint8 seed = uint8(uint256(keccak256(abi.encode(block.timestamp))));

        for (uint256 i = 0; i < amount; i++) {
            seed = uint8(uint256(keccak256(abi.encode(seed))));
            randomBytes[i] = bytes1(uint8(seed));
        }

        return randomBytes;
    }

    function sliceBytes(bytes memory data, uint256 chunkSize) public pure returns (bytes[] memory) {
        uint256 numOfChunks = data.length / chunkSize;
        bytes[] memory chunks = new bytes[](numOfChunks);

        uint256 start;
        bytes memory chunk;
        for (uint256 i; i < numOfChunks; i++) {
            start = i * chunkSize;
            chunk = new bytes(chunkSize);
            for (uint256 j; j < chunkSize; j++) {
                chunk[j] = data[start + j];
            }
            chunks[i] = chunk;
        }
        return chunks;
    }
}
