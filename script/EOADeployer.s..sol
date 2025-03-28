// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/EOAEnsoShortcuts.sol";

struct DeployerResult {
    EOAEnsoShortcuts shortcuts;
}

contract Deployer is Script {
    function run() public returns (DeployerResult memory result) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        result.shortcuts = new EOAEnsoShortcuts{salt: "EOAEnsoShortcuts"}();

        vm.stopBroadcast();
    }
}
