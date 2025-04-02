// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.28;

import { VM } from "enso-weiroll/VM.sol";
import { ERC721Holder } from "openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract EnsoShortcuts is VM, ERC721Holder, ERC1155Holder {
    address public executor;

    error NotPermitted();

    constructor(address executor_) {
        executor = executor_;
    }

    // @notice Execute a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable returns (bytes[] memory) {
        if (msg.sender != executor) revert NotPermitted();
        return _execute(commands, state);
    }

    receive() external payable {}
}