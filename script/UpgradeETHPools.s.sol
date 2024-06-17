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

contract UpgradeETHPoolsScript is Script {
    address public proxyAdminAddress = 0x076CF237f609de0066AbC0974673Ab376992E4D2; // Replace with actual Proxy Admin address

    address public ethPoolAddress = 0xB77Fc2ee5FC04465C2719A0055542ed8cE8611E0;
    address public stETHPoolAddress = 0x2Ed364335E0ef6308D86b96F28c9151bB7ccE11F;
    address public stakestonePoolAddress = 0x5a9167D96c5Ad4fd97F86263cA583C3bC7ef2F34;

    address public newImplementationAddress;

    function run() public {
        vm.startBroadcast();

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        ITransparentUpgradeableProxy stETHPool_proxy = ITransparentUpgradeableProxy(stETHPoolAddress);
        // Deploy new implementation
        ORAStakePool_StETH newStETHPoolImpl = new ORAStakePool_StETH();
        newImplementationAddress = address(newStETHPoolImpl);
        proxyAdmin.upgrade(stETHPool_proxy, newImplementationAddress);

        ITransparentUpgradeableProxy ethPool_proxy = ITransparentUpgradeableProxy(ethPoolAddress);

        ORAStakePool_ETH newETHPoolImpl = new ORAStakePool_ETH();
        newImplementationAddress = address(newETHPoolImpl);
        proxyAdmin.upgrade(ethPool_proxy, newImplementationAddress);

        ITransparentUpgradeableProxy stakestoneETHPool_proxy = ITransparentUpgradeableProxy(stakestonePoolAddress);

        ORAStakePool_StakeStoneETH newStakeStoneETHPoolImpl = new ORAStakePool_StakeStoneETH();
        newImplementationAddress = address(newStakeStoneETHPoolImpl);
        proxyAdmin.upgrade(stakestoneETHPool_proxy, newImplementationAddress);
        //optional: fix existing data
        vm.stopBroadcast();
    }
}
