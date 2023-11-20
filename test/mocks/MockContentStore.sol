// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract MockContentStore {
    function getPointer(bytes32 _checksum) external pure returns (address) {
        return address(uint160(uint256(_checksum)));
    }
}
