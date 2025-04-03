// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/EnsoShortcuts.sol";
import "../src/router/EnsoRouter.sol";
import "../src/delegate/DelegateEnsoShortcuts.sol";

struct DeployerResult {
    EnsoRouter router;
    EnsoShortcuts shortcuts;
    DelegateEnsoShortcuts delegate;
}

contract Deployer is Script {
    function run() public returns (DeployerResult memory result) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        result.router = new EnsoRouter{salt: "EnsoRouter"}();
        result.shortcuts = new EnsoShortcuts{salt: "EnsoShortcuts"}(address(result.router));
        result.delegate = new DelegateEnsoShortcuts{salt: "DelegateEnsoShortcuts"}();

        vm.stopBroadcast();
    }
}
