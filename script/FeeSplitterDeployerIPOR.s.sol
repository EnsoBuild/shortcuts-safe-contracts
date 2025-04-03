// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";

import {FeeSplitter} from "../src/helpers/FeeSplitter.sol";

struct DeployerResult {
    FeeSplitter feeSplitter;
}

// Deployer for the IPOR FeeSplitter
contract DeployerIPOR is Script {
      function run() public returns (DeployerResult memory result) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address[] memory recipients = new address[](2);
        recipients[0] = 0xB7bE82790d40258Fd028BEeF2f2007DC044F3459; // ipor multisig
        recipients[1] = 0x2C0b46F1276A93B458346e53f6B7B57Aba20D7D1; // enso multisig

        uint16[] memory shares = new uint16[](2);
        shares[0] = 1;
        shares[1] = 1;

        vm.broadcast(deployerPrivateKey);
        result.feeSplitter = new FeeSplitter(vm.envAddress("OWNER"), recipients, shares);
    }
}
