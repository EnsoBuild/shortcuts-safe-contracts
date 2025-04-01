// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {WETH} from "solady/tokens/WETH.sol";
import {EOADeployer, EOADeployerResult} from "../script/EOADeployer.s.sol";
import {EOAEnsoShortcuts} from "../src/EOAEnsoShortcuts.sol";
import {WeirollPlanner} from "./utils/WeirollPlanner.sol";

contract EOAEnsoShortcutsTest is Test {
    bytes3 private constant PREFIX = 0xef0100;
    address private constant CALLER_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 private constant CALLER_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    address private s_alice;
    address private s_deployer;
    EOAEnsoShortcuts private s_eoaDelegate;
    WETH private s_weth;

    event ShortcutExecuted(bytes32 requestId);

    function setUp() public {
        s_deployer = address(0);
        s_alice = address(1);

        deal(s_deployer, 1 ether);

        vm.prank(s_deployer);
        EOADeployerResult memory result = new EOADeployer().run();
        s_eoaDelegate = result.shortcuts;

        s_weth = new WETH();

        assertTrue(CALLER_ADDRESS.code.length == 0);
        vm.signAndAttachDelegation(address(s_eoaDelegate), CALLER_PK);
    }

    function testEOAHasDelegateCode() public view {
        // Arrange
        bytes memory expectedCode = abi.encodePacked(PREFIX, address(s_eoaDelegate));

        // Assert
        assertEq(CALLER_ADDRESS.code, expectedCode);
    }

    function testEOACanClearDelegateCode() public {
        // Arrange
        bytes memory expectedCode = abi.encodePacked(PREFIX, address(s_eoaDelegate));

        // Act
        vm.signAndAttachDelegation(address(0), CALLER_PK);

        // Assert
        assertNotEq(CALLER_ADDRESS.code, expectedCode);
    }

    function testExecuteShortcutReverts() public {
        // Arrange
        bytes32 requestId = bytes32(0);
        bytes32[] memory commands = new bytes32[](1);
        bytes[] memory state = new bytes[](1);

        // Act & Assert
        vm.prank(s_deployer);
        vm.expectRevert(EOAEnsoShortcuts.OnlySelfCall.selector);
        EOAEnsoShortcuts(payable(CALLER_ADDRESS)).executeShortcut(requestId, commands, state);
    }

    function testExecuteShortcutSucceeds() public {
        // Arrange
        bytes32 requestId = keccak256(abi.encodePacked("requestId"));

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

        deal(address(s_weth), address(CALLER_ADDRESS), 10 ether);

        // Act & Assert
        vm.prank(CALLER_ADDRESS);
        vm.expectEmit(CALLER_ADDRESS);
        emit ShortcutExecuted(requestId);
        bytes[] memory returnData =
            EOAEnsoShortcuts(payable(CALLER_ADDRESS)).executeShortcut(requestId, commands, state);

        assertTrue(returnData.length > 0);
        assertEq(s_weth.balanceOf(CALLER_ADDRESS), 0);
        assertEq(s_weth.balanceOf(address(s_eoaDelegate)), 0);
        assertEq(s_weth.balanceOf(s_alice), 10 ether);
    }

    // function testExecuteReverts() public {
    //     // Arrange
    //     bytes32 requestId = bytes32(0);
    //     bytes32[] memory commands = new bytes32[](1);
    //     bytes[] memory state = new bytes[](1);

    //     bytes memory data = abi.encodeCall(EOAEnsoShortcuts.executeShortcut, (requestId, commands, state));

    //     // Act & Assert
    //     vm.prank(s_deployer);
    //     vm.expectRevert(EOAEnsoShortcuts.OnlySelfCall.selector);
    //     EOAEnsoShortcuts(payable(CALLER_ADDRESS)).execute(payable(CALLER_ADDRESS), 0, data);
    // }

    // function testExecuteSucceeds() public {
    //     // Arrange
    //     bytes32 requestId = keccak256(abi.encodePacked("requestId"));

    //     bytes32[] memory commands = new bytes32[](1);
    //     commands[0] = WeirollPlanner.buildCommand(
    //         s_weth.transfer.selector,
    //         0x01, // call
    //         0x0001ffffffff, // 2 inputs
    //         0xff, // no output
    //         address(s_weth)
    //     );

    //     bytes[] memory state = new bytes[](2);
    //     state[0] = abi.encode(s_alice);
    //     state[1] = abi.encode(10 ether);

    //     bytes memory data = abi.encodeCall(EOAEnsoShortcuts.executeShortcut, (requestId, commands, state));

    //     deal(address(s_weth), address(CALLER_ADDRESS), 10 ether);

    //     // Act & Assert
    //     vm.prank(CALLER_ADDRESS);
    //     vm.expectEmit(CALLER_ADDRESS);
    //     emit ShortcutExecuted(requestId);
    //     bool success = EOAEnsoShortcuts(payable(CALLER_ADDRESS)).execute(payable(CALLER_ADDRESS), 0, data);

    //     assertTrue(success);
    //     assertEq(s_weth.balanceOf(CALLER_ADDRESS), 0);
    //     assertEq(s_weth.balanceOf(address(s_eoaDelegate)), 0);
    //     assertEq(s_weth.balanceOf(s_alice), 10 ether);
    // }
}
