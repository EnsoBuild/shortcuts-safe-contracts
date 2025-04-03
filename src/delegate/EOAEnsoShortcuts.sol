// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.28;

import { AbstractEnsoShortcuts } from "../AbstractEnsoShortcuts.sol";

contract EOAEnsoShortcuts is AbstractEnsoShortcuts {
    error OnlySelfCall();

    function _checkMsgSender() internal override view {
        if (msg.sender != address(this)) revert OnlySelfCall();
    }
}