// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/*//////////////////////////////////////////////////////////////////////////
                                CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

// Metadata
bytes1 constant DIRECTORY_TYPE = bytes1(0x01);
bytes1 constant FILE_TYPE = bytes1(0x00);

// Characters
uint256 constant CHARACTER_LENGTH = 18;
string constant FORBIDDEN_CHARS = ":/?#[]@!$&'()*+,;=";
