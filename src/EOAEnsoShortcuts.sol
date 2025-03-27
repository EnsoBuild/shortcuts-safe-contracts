// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.17;

import {VM} from "enso-weiroll/VM.sol";

contract EOAEnsoShortcuts is VM {
    event ShortcutExecuted(bytes32 shortcutId);

    error OnlySelfCall();

    // @notice Execute a shortcut on EOA that set this contract as its account code
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable returns (bytes[] memory returnData) {
        if (msg.sender != address(this)) revert OnlySelfCall();
        returnData = _execute(commands, state);
        emit ShortcutExecuted(shortcutId);
    }

    // @notice A function to execute an arbitrary call on another contract
    // @param target The address of the target contract
    // @param value The ether value that is to be sent with the call
    // @param data The call data to be sent to the target
    function execute(
        address target,
        uint256 value,
        bytes memory data
    ) external payable isPermitted(EXECUTOR_ROLE) returns (bool success) {
        if (msg.sender != address(this)) revert OnlySelfCall();
        assembly {
            success := call(gas(), target, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    receive() external payable {}
}