// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ProxyAdmin} from "@openzeppelin-contract/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin-contract/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ORAStakePool_StETH} from "../src/ORAStakePool_STETH.sol";
import {ORAStakePool_StakeStoneETH} from "../src/ORAStakePool_StakeStoneETH.sol";
import {ORAStakePool_ETH} from "../src/ORAStakePool_ETH.sol";
import {ORAStakePool_OLM} from "../src/ORAStakePool_OLM.sol";

contract UpgradeOLMPoolsScript is Script {
    address public proxyAdminAddress = 0x076CF237f609de0066AbC0974673Ab376992E4D2; // Replace with actual Proxy Admin address

    address public olmPoolAddress = 0xA18187Ca69F075AAA59F17742803b988E9996d04;

    address public newImplementationAddress;

    function run() public {
        vm.startBroadcast();

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        ITransparentUpgradeableProxy olmPool_proxy = ITransparentUpgradeableProxy(olmPoolAddress);
        // Deploy new implementation
        ORAStakePool_OLM newOLMPoolImpl = new ORAStakePool_OLM();
        newImplementationAddress = address(newOLMPoolImpl);
        proxyAdmin.upgrade(olmPool_proxy, newImplementationAddress);

        vm.stopBroadcast();
    }
}
