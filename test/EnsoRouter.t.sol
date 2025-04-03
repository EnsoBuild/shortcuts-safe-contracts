// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../lib/forge-std/src/Test.sol";
import "../src/router/EnsoRouter.sol";
import "../src/EnsoShortcuts.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockVault.sol";
import "./utils/WeirollPlanner.sol";

contract EnsoRouterTest is Test {
    EnsoRouter public router;
    EnsoShortcuts public shortcuts;
    MockERC20 public token;
    MockVault public vault;

    string _rpcURL = vm.envString("ETHEREUM_RPC_URL");
    uint256 _ethereumFork;

    uint256 public constant AMOUNT = 10 ** 18;

    

    function setUp() public {
        _ethereumFork = vm.createFork(_rpcURL);
        vm.selectFork(_ethereumFork);
        router = new EnsoRouter();
        shortcuts = new EnsoShortcuts(address(router));
        token = new MockERC20("Test", "TST");
        vault = new MockVault("Vault", "VLT", address(token));
        token.mint(address(this), AMOUNT * 10);
    }

    function testVaultDeposit() public {
        vm.selectFork(_ethereumFork);

        token.approve(address(router), AMOUNT);

        bytes32[] memory commands = new bytes32[](3);
        bytes[] memory state = new bytes[](3);

        commands[0] = WeirollPlanner.buildCommand(
            token.approve.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(token)
        );
    
        commands[1] = WeirollPlanner.buildCommand(
            vault.deposit.selector,
            0x01, // call
            0x01ffffffffff, // 1 input
            0xff, // no output
            address(vault)
        );

        commands[2] = WeirollPlanner.buildCommand(
            vault.transfer.selector,
            0x01, // call
            0x0201ffffffff, // 2 inputs
            0xff, // no output
            address(vault)
        );

        state[0] = abi.encode(address(vault));
        state[1] = abi.encode(AMOUNT);
        state[2] = abi.encode(address(this));

        bytes memory data = abi.encodeWithSelector(shortcuts.executeShortcut.selector, bytes32(0), bytes32(0), commands, state);

        Token memory tokenIn = Token(TokenType.ERC20, abi.encode(address(token), AMOUNT));
        Token memory tokenOut = Token(TokenType.ERC20, abi.encode(address(vault), AMOUNT));

        router.safeRouteSingle(tokenIn, tokenOut, address(this), address(shortcuts), data);
        assertEq(AMOUNT, vault.balanceOf(address(this)));
    }

    function test_RevertWhen_VaultDepositNoApproval() public {
        vm.selectFork(_ethereumFork);

        bytes32[] memory commands = new bytes32[](3);
        bytes[] memory state = new bytes[](3);

        commands[0] = WeirollPlanner.buildCommand(
            token.approve.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(token)
        );
    
        commands[1] = WeirollPlanner.buildCommand(
            vault.deposit.selector,
            0x01, // call
            0x01ffffffffff, // 1 input
            0xff, // no output
            address(vault)
        );

        commands[2] = WeirollPlanner.buildCommand(
            vault.transfer.selector,
            0x01, // call
            0x0201ffffffff, // 2 inputs
            0xff, // no output
            address(vault)
        );

        state[0] = abi.encode(address(vault));
        state[1] = abi.encode(AMOUNT);
        state[2] = abi.encode(address(this));

        bytes memory data = abi.encodeWithSelector(shortcuts.executeShortcut.selector, bytes32(0), bytes32(0), commands, state);
        
        Token memory tokenIn = Token(TokenType.ERC20, abi.encode(address(token), AMOUNT));
        Token memory tokenOut = Token(TokenType.ERC20, abi.encode(address(vault), AMOUNT));

        vm.expectRevert();
        router.safeRouteSingle(tokenIn, tokenOut, address(this), address(shortcuts), data);
    }

    function test_RevertWhen_VaultDepositNoTransfer() public {
        vm.selectFork(_ethereumFork);

        token.approve(address(router), AMOUNT);

        // Shortcut does not transfer funds after deposit
        bytes32[] memory commands = new bytes32[](2);
        bytes[] memory state = new bytes[](2);
        
        commands[0] = WeirollPlanner.buildCommand(
            token.approve.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(token)
        );
    
        commands[1] = WeirollPlanner.buildCommand(
            vault.deposit.selector,
            0x01, // call
            0x01ffffffffff, // 1 input
            0xff, // no output
            address(vault)
        );

        state[0] = abi.encode(address(vault));
        state[1] = abi.encode(AMOUNT);

        bytes memory data = abi.encodeWithSelector(shortcuts.executeShortcut.selector, bytes32(0), bytes32(0), commands, state);

        Token memory tokenIn = Token(TokenType.ERC20, abi.encode(address(token), AMOUNT));
        Token memory tokenOut = Token(TokenType.ERC20, abi.encode(address(vault), AMOUNT));

        vm.expectRevert();
        router.safeRouteSingle(tokenIn, tokenOut, address(this), address(shortcuts), data);
    }

    function testUnsafeVaultDepositNoTransfer() public {
        vm.selectFork(_ethereumFork);

        token.approve(address(router), AMOUNT);

        // Shortcut does not transfer funds after deposit
        bytes32[] memory commands = new bytes32[](2);
        bytes[] memory state = new bytes[](2);
        
        commands[0] = WeirollPlanner.buildCommand(
            token.approve.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(token)
        );
    
        commands[1] = WeirollPlanner.buildCommand(
            vault.deposit.selector,
            0x01, // call
            0x01ffffffffff, // 1 input
            0xff, // no output
            address(vault)
        );

        state[0] = abi.encode(address(vault));
        state[1] = abi.encode(AMOUNT);

        bytes memory data = abi.encodeWithSelector(shortcuts.executeShortcut.selector, bytes32(0), bytes32(0), commands, state);

        Token memory tokenIn = Token(TokenType.ERC20, abi.encode(address(token), AMOUNT));

        router.routeSingle(tokenIn, address(shortcuts), data);
        // Funds left in router's wallet!
        assertEq(AMOUNT, vault.balanceOf(address(shortcuts)));
    }
    
    function testRouteMulti() public {
        vm.selectFork(_ethereumFork);

        token.approve(address(router), AMOUNT);

        bytes32[] memory commands = new bytes32[](3);
        bytes[] memory state = new bytes[](3);

        commands[0] = WeirollPlanner.buildCommand(
            token.approve.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(token)
        );
    
        commands[1] = WeirollPlanner.buildCommand(
            vault.deposit.selector,
            0x01, // call
            0x01ffffffffff, // 1 input
            0xff, // no output
            address(vault)
        );

        commands[2] = WeirollPlanner.buildCommand(
            vault.transfer.selector,
            0x01, // call
            0x0201ffffffff, // 2 inputs
            0xff, // no output
            address(vault)
        );

        state[0] = abi.encode(address(vault));
        state[1] = abi.encode(AMOUNT);
        state[2] = abi.encode(address(this));

        bytes memory data = abi.encodeWithSelector(shortcuts.executeShortcut.selector, bytes32(0), bytes32(0), commands, state);

        Token[] memory tokensIn = new Token[](2);
        tokensIn[0] = Token(TokenType.ERC20, abi.encode(address(token), AMOUNT));
        tokensIn[1] = Token(TokenType.Native, abi.encode(uint256(1)));

        router.routeMulti{ value: 1 }(tokensIn, address(shortcuts), data);
        assertEq(AMOUNT, vault.balanceOf(address(this)));
    }

    function testSafeRouteMulti() public {
        vm.selectFork(_ethereumFork);

        token.approve(address(router), AMOUNT);

        bytes32[] memory commands = new bytes32[](3);
        bytes[] memory state = new bytes[](3);

        commands[0] = WeirollPlanner.buildCommand(
            token.approve.selector,
            0x01, // call
            0x0001ffffffff, // 2 inputs
            0xff, // no output
            address(token)
        );
    
        commands[1] = WeirollPlanner.buildCommand(
            vault.deposit.selector,
            0x01, // call
            0x01ffffffffff, // 1 input
            0xff, // no output
            address(vault)
        );

        commands[2] = WeirollPlanner.buildCommand(
            vault.transfer.selector,
            0x01, // call
            0x0201ffffffff, // 2 inputs
            0xff, // no output
            address(vault)
        );

        state[0] = abi.encode(address(vault));
        state[1] = abi.encode(AMOUNT);
        state[2] = abi.encode(address(this));

        bytes memory data = abi.encodeWithSelector(shortcuts.executeShortcut.selector, bytes32(0), bytes32(0), commands, state);

        Token[] memory tokensIn = new Token[](2);
        tokensIn[0] = Token(TokenType.ERC20, abi.encode(address(token), AMOUNT));
        tokensIn[1] = Token(TokenType.Native, abi.encode(uint256(1)));

        Token[] memory tokensOut = new Token[](1);
        tokensOut[0] = Token(TokenType.ERC20, abi.encode(address(vault), AMOUNT));

        router.safeRouteMulti{ value: 1 }(tokensIn, tokensOut, address(this), address(shortcuts), data);
        assertEq(AMOUNT, vault.balanceOf(address(this)));
    }
}
