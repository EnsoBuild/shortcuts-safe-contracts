// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SafeEnsoShortcuts} from "../src/SafeEnsoShortcuts.sol";
import {WeirollPlanner} from "./utils/WeirollPlanner.sol";

contract SafeEnsoShortcutsTest is Test {
    SafeEnsoShortcuts shortcuts;

    function setUp() public {
        // Invoke deploy script
        shortcuts = new SafeEnsoShortcuts();
    }

    function testSafeCanRunShortcut() public {
        bytes32[] memory commands = new bytes32[](2);
        bytes[] memory state = new bytes[](2);

        commands[0] = WeirollPlanner.buildCommand(
            token0.approve.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(token0)
        );

        commands[1] = WeirollPlanner.buildCommand(
            vault.deposit.selector,
            0x01, // call
            0x01ffffffffff, // 1 input
            0xff, // no output
            address(vault)
        );

        state[0] = abi.encode(address(vault));
        state[1] = abi.encode(defaultAmount);

        uint256 deadline = block.timestamp + 100;
        IAllowanceTransfer.PermitDetails memory details = IAllowanceTransfer.PermitDetails({
            token: address(token0),
            amount: defaultAmount,
            expiration: defaultExpiration,
            nonce: defaultNonce
        });
        IAllowanceTransfer.PermitSingle memory permit =
            IAllowanceTransfer.PermitSingle({details: details, spender: address(shortcuts), sigDeadline: deadline});
        bytes memory sig = getPermitSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        vm.startPrank(from);
        shortcuts.permit2AndExecuteShortcut(bytes32(0), commands, state, details, deadline, sig);
        vm.stopPrank();

        uint256 depositedAmount = vault.deposits(address(shortcuts));
        assertEq(uint256(defaultAmount), depositedAmount);
    }
}
