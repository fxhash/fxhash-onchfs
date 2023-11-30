// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {FileSystem} from "src/FileSystem.sol";

import "script/utils/Constants.sol";

contract Deploy is Script {
    /*//////////////////////////////////////////////////////////////////////////
                                      RUN
    //////////////////////////////////////////////////////////////////////////*/
    function run() public virtual {
        bytes32 salt = keccak256(abi.encode("ONCHFS"));
        bytes memory creationCode = type(FileSystem).creationCode;
        vm.startBroadcast();
        _deployCreate2(creationCode, salt);
        vm.stopBroadcast();
    }

    function _deployCreate2(bytes memory _creationCode, bytes32 _salt) internal returns (address deployedAddr) {
        deployedAddr = _deployCreate2(_creationCode, bytes(""), _salt);
    }

    function _deployCreate2(
        bytes memory _creationCode,
        bytes memory _constructorArgs,
        bytes32 _salt
    ) internal returns (address deployedAddr) {
        (bool success, bytes memory response) = CREATE2_FACTORY.call(
            bytes.concat(_salt, _creationCode, _constructorArgs)
        );
        deployedAddr = address(bytes20(response));
        require(success, "deployment failed");
    }
}
