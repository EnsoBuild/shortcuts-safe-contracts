// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {WETH} from "solady/tokens/WETH.sol";
import {EOADeployer, EOADeployerResult} from "../script/EOADeployer.s.sol";
import {EOAEnsoShortcuts} from "../src/EOAEnsoShortcuts.sol";
import {WeirollPlanner} from "./utils/WeirollPlanner.sol";

// TODO:
// executeShortcut
// - if msg.sender != address(this) then reverts
// - else: executs shortcut, emits event & returns data
//
// execute:
// - if msg.sender != address(this) then reverts
// - else: executes call & returns success
//
// Requirements: 7702 prague & cheatcodes
contract EOAEnsoShortcutsTest is Test {
    address private constant CALLER_ADDRESS =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant CALLER_PK =
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    address private s_alice;
    address private s_deployer;
    EOAEnsoShortcuts private s_eoaDelegate;
    WETH private s_weth;

    function setUp() public {
        s_deployer = address(0);
        s_alice = address(1);

        deal(s_deployer, 1 ether);

        vm.prank(s_deployer);
        EOADeployerResult memory result = new EOADeployer().run();
        s_eoaDelegate = result.shortcuts;

        s_weth = new WETH();

        vm.signAndAttachDelegation(address(s_eoaDelegate), CALLER_PK);
    }

    function testExecuteShortcutReverts() public {
        // Arrange
        bytes32[] memory commands = new bytes32[](1);
        commands[0] = WeirollPlanner.buildCommand(
            s_weth.transfer.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(s_weth)
        );

        bytes[] memory state = new bytes[](2);
        state[0] = abi.encode(s_alice);
        state[1] = abi.encode(10 ether);

        // Act
        vm.expectRevert(EOAEnsoShortcuts.OnlySelfCall.selector);
        vm.prank(s_deployer);
        bytes memory data = abi.encodeCall(
            EOAEnsoShortcuts.executeShortcut,
            (bytes32(0), commands, state)
        );
    }

    // function testCanRunShortcutTransferringERC20() public {
    //     bytes32[] memory commands = new bytes32[](1);
    //     commands[0] = WeirollPlanner.buildCommand(
    //         weth.transfer.selector,
    //         0x01, // call
    //         0x0001ffffffff, // 2 inputs
    //         0xff, // no output
    //         address(weth)
    //     );

    //     bytes[] memory state = new bytes[](2);
    //     state[0] = abi.encode(alice);
    //     state[1] = abi.encode(10 ether);

    //     bytes memory data = abi.encodeCall(
    //         SafeEnsoShortcuts.executeShortcut,
    //         (bytes32(0), commands, state)
    //     );

    //     assertEq(weth.balanceOf(address(safeInstance.safe)), 0);
    //     assertEq(weth.balanceOf(alice), 0);

    //     deal(address(weth), address(safeInstance.safe), 10 ether);

    //     assertEq(weth.balanceOf(address(safeInstance.safe)), 10 ether);
    //     assertEq(weth.balanceOf(alice), 0);

    //     safeInstance.execTransaction({
    //         to: address(shortcuts),
    //         value: 0 ether,
    //         data: data,
    //         operation: Enum.Operation.DelegateCall
    //     });

    //     assertEq(weth.balanceOf(address(safeInstance.safe)), 0);
    //     assertEq(weth.balanceOf(alice), 10 ether);
    // }

    // function testSafeCanRunShortcutDepositingEther() public {
    //     bytes32[] memory commands = new bytes32[](1);
    //     commands[0] = WeirollPlanner.buildCommand(
    //         weth.deposit.selector,
    //         0x03, // call with value
    //         0x00ffffffffff, // 1 input
    //         0xff, // no output
    //         address(weth)
    //     );

    //     bytes[] memory state = new bytes[](1);
    //     state[0] = abi.encode(10 ether);

    //     bytes memory data = abi.encodeCall(
    //         SafeEnsoShortcuts.executeShortcut,
    //         (bytes32(0), commands, state)
    //     );

    //     uint256 safeBalanceBefore = address(safeInstance.safe).balance;
    //     assertEq(weth.balanceOf(address(safeInstance.safe)), 0);

    //     safeInstance.execTransaction({
    //         to: address(shortcuts),
    //         value: 0 ether,
    //         data: data,
    //         operation: Enum.Operation.DelegateCall
    //     });

    //     assertEq(weth.balanceOf(address(safeInstance.safe)), 10 ether);
    //     assertEq(
    //         safeBalanceBefore - 10 ether,
    //         address(safeInstance.safe).balance
    //     );
    // }
}
