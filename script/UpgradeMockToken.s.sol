// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ProxyAdmin} from "@openzeppelin-contract/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin-contract/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {MyToken} from "../src/mock/MockERC20Upgradeable.sol";

contract UpgradeMockTokenScript is Script {
    address public proxyAdminAddress = 0x076CF237f609de0066AbC0974673Ab376992E4D2; // Replace with actual Proxy Admin address

    address public stETHTokenProxy = 0x5FeC619342077cdB90652205535DBFCa6a1126fC;

    address public newImplementationAddress;

    function run() public {
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(stETHTokenProxy);

        vm.startBroadcast();

        // Deploy new implementation
        MyToken newStETHImpl = new MyToken();
        newImplementationAddress = address(newStETHImpl);

        // Upgrade to new implementation
        proxyAdmin.upgrade(proxy, newImplementationAddress);

        //optional: fix existing data
        vm.stopBroadcast();
    }
}
