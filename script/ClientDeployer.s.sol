// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/router/EnsoShortcutRouter.sol";
import "../src/delegate/DelegateEnsoShortcuts.sol";

struct DeployerResult {
    EnsoShortcutRouter router;
    EnsoShortcuts shortcuts;
    DelegateEnsoShortcuts delegate;
}

contract Deployer is Script {
    function run() public returns (DeployerResult memory result) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        result.router = new EnsoShortcutRouter{salt: "EnsoShortcutRouter"}();
        result.shortcuts = result.router.enso();
        result.delegate = new DelegateEnsoShortcuts{salt: "DelegateEnsoShortcuts"}();

        vm.stopBroadcast();
    }
}
