// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

import {VM} from "enso-weiroll/VM.sol";
import {MinimalWallet} from "shortcuts-contracts/wallet/MinimalWallet.sol";
import {AccessController} from "shortcuts-contracts/access/AccessController.sol";

contract BaseSolver is VM, MinimalWallet, AccessController {
    address private immutable executor;

    // @dev Event emitted when a new request is made, uniquely identified by its `id`.
    // @param id A `bytes32` value that uniquely identifies a specific request.
    event RequestId(bytes32 indexed id);

    // @dev Constructor for the `BaseSolver` contract.
    // @param _owner The address of the owner who will be assigned the `OWNER_ROLE`. This parameter cannot be null.
    // @param _executor The address of the executor contract that interacts with this contract.
    constructor(address _owner, address _executor) {
        _setPermission(OWNER_ROLE, _owner, true);
        if (_executor == address(0)) {
            revert NotPermitted();
        }
        executor = _executor;
    }

    // @notice Executes a series of pre-encoded commands (shortcuts) on behalf of a solver.
    // @param requestId A unique identifier (bytes32) used to correlate the current request with a previously provided quote.
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(
        bytes32 requestId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) public payable virtual returns (bytes[] memory response) {
        // we could use the AccessController here to check if the msg.sender is the executor address
        // but as it's a hot path we do a less gas intensive check
        if (msg.sender != executor) {
            revert NotPermitted();
        }
        response = _execute(commands, state);
        emit RequestId(requestId);
    }
}
