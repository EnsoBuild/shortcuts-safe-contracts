// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.17;

import {VM} from "enso-weiroll/VM.sol";

contract SafeEnsoShortcuts is VM {
    address private immutable __self = address(this);

    event ShortcutExecuted(bytes32 shortcutId);

    error OnlyDelegateCall();

    // @notice Execute a shortcut via delegate call
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable returns (bytes[] memory returnData) {
        if (address(this) == __self) revert OnlyDelegateCall();
        returnData = _execute(commands, state);
        emit ShortcutExecuted(shortcutId);
    }
}