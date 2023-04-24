// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Deployer, DeployerResult} from "../script/Deployer.s.sol";
import {SafeEnsoShortcuts} from "../src/SafeEnsoShortcuts.sol";
import {WeirollPlanner} from "./utils/WeirollPlanner.sol";

contract SafeEnsoShortcutsTest is Test {
    SafeEnsoShortcuts shortcuts;

    function setUp() public {
        DeployerResult memory result = new Deployer().run();

        shortcuts = result.shortcuts;
    }

    function testSafeCanRunShortcut() public {
        bytes32[] memory commands = new bytes32[](1);
        commands[0] = WeirollPlanner.buildCommand(
            SafeEnsoShortcutsTest(address(this)).testSafeCanRunShortcut.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(this)
        );

        bytes[] memory state = new bytes[](1);
        state[0] = abi.encode(0x1);

        shortcuts.executeShortcut(bytes32(0), commands, state);
    }
}
