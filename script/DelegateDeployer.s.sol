// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/delegate/DelegateEnsoShortcuts.sol";

struct DelegateDeployerResult {
    DelegateEnsoShortcuts shortcuts;
}

contract DelegateDeployer is Script {
    function run() public returns (DelegateDeployerResult memory result) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        result.shortcuts = new DelegateEnsoShortcuts{salt: "DelegateEnsoShortcuts"}();

        vm.stopBroadcast();
    }
}
