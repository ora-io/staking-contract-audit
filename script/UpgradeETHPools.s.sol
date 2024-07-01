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

    address public ethPoolAddress = 0x30CA6c5bc35cddE12bB0f3E4198C01ed2D6857f0;
    address public stETHPoolAddress = 0x30e1bFA947A7161Fce423056394B7e537199964c;
    address public stakestonePoolAddress = 0x0D563e769409902e4f7B45a8EE00AA44F8344A88;

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

        logAddress("STETHPOOL_IMPLEMENTATION_ADDR", address(newStETHPoolImpl));
        logAddress("ETHPOOL_IMPLEMENTATION_ADDR", address(newETHPoolImpl));
        logAddress("STONEETHPOOL_IMPLEMENTATION_ADDR", address(newStakeStoneETHPoolImpl));

        vm.stopBroadcast();
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
