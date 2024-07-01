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

    address public olmPoolAddress = 0x7be1D0C1641E5FDD55f4b3D682Fe21Da2963fE2b;

    address public newImplementationAddress;

    function run() public {
        vm.startBroadcast();

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        ITransparentUpgradeableProxy olmPool_proxy = ITransparentUpgradeableProxy(olmPoolAddress);
        // Deploy new implementation
        ORAStakePool_OLM newOLMPoolImpl = new ORAStakePool_OLM();
        newImplementationAddress = address(newOLMPoolImpl);
        proxyAdmin.upgrade(olmPool_proxy, newImplementationAddress);

        logAddress("OLMPOOL_IMPLEMENTATION_ADDR", address(newOLMPoolImpl));
        vm.stopBroadcast();
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
