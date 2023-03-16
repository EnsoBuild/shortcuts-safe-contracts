// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SafeEnsoShortcuts.sol";

contract Deployer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SafeEnsoShortcuts shortcuts = new SafeEnsoShortcuts{salt: "SafeEnsoShortcuts"}();

        vm.stopBroadcast();
    }
}
