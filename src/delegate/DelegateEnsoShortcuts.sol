// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.28;

import {VM} from "enso-weiroll/VM.sol";

contract DelegateEnsoShortcuts is VM {
    address private immutable __self = address(this);

    event ShortcutExecuted(bytes32 accountId, bytes32 requestId);

    error OnlyDelegateCall();

    // @notice Execute a shortcut via delegate call
    // @param accountId The bytes32 value representing an API user
    // @param requestId The bytes32 value representing an API request
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(bytes32 accountId, bytes32 requestId, bytes32[] calldata commands, bytes[] calldata state)
        external
        payable
        returns (bytes[] memory returnData)
    {
        if (address(this) == __self) revert OnlyDelegateCall();
        returnData = _execute(commands, state);
        emit ShortcutExecuted(accountId, requestId);
    }
}
