// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.17;

import {VM} from "enso-weiroll/VM.sol";

contract EOAEnsoShortcuts is VM {
    event ShortcutExecuted(bytes32 requestId);

    error OnlySelfCall();

    /// @notice Execute a shortcut on EOA that set this contract as its account code
    /// @param requestId The bytes32 value representing an API request
    /// @param commands An array of bytes32 values that encode calls
    /// @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(bytes32 requestId, bytes32[] calldata commands, bytes[] calldata state)
        external
        returns (bytes[] memory returnData)
    {
        if (msg.sender != address(this)) revert OnlySelfCall();
        returnData = _execute(commands, state);
        emit ShortcutExecuted(requestId);
    }

    /// @dev Sends multiple transactions and reverts all if one fails.
    /// @param transactions Encoded transactions. Each transaction is encoded as a packed bytes of
    ///                     operation has to be uint8(0) in this version (=> 1 byte),
    ///                     to as a address (=> 20 bytes),
    ///                     value as a uint256 (=> 32 bytes),
    ///                     data length as a uint256 (=> 32 bytes),
    ///                     data as bytes.
    ///                     see abi.encodePacked for more information on packed encoding
    /// @notice The code is for most part the same as the normal MultiSend (to keep compatibility),
    ///         but reverts if a transaction tries to use a delegatecall.
    function multiSend(bytes memory transactions) public {
        if (msg.sender != address(this)) revert OnlySelfCall();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let length := mload(transactions)
            let i := 0x20
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) it right since mload will always load 32 bytes (a word).
                // This will also zero out unused data.
                let operation := shr(0xf8, mload(add(transactions, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                let value := mload(add(transactions, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                let dataLength := mload(add(transactions, add(i, 0x35)))
                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                let data := add(transactions, add(i, 0x55))
                let success := 0
                switch operation
                case 0 { success := call(gas(), to, value, data, dataLength, 0, 0) }
                // This version does not allow delegatecalls
                case 1 { revert(0, 0) }
                if eq(success, 0) { revert(0, 0) }
                // Next entry starts at 85 byte + data length
                i := add(i, add(0x55, dataLength))
            }
        }
    }

    receive() external payable {}
}
