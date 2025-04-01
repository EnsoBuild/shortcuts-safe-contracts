// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SafeEnsoShortcuts.sol";

struct DelegateDeployerResult {
    SafeEnsoShortcuts shortcuts;
}

contract DelegateDeployer is Script {
    function run() public returns (DelegateDeployerResult memory result) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        result.shortcuts = new SafeEnsoShortcuts{salt: "SafeEnsoShortcuts"}();

        vm.stopBroadcast();
    }
}
