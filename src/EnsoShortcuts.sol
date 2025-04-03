// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.28;

import { AbstractEnsoShortcuts } from "./AbstractEnsoShortcuts.sol";

contract EnsoShortcuts is AbstractEnsoShortcuts {
    address immutable public executor;

    error NotPermitted();

    constructor(address executor_) {
        executor = executor_;
    }

    function _checkMsgSender() internal override view {
        if (msg.sender != executor) revert NotPermitted();
    }
}