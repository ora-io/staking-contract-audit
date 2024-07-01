// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ProxyAdmin} from "@openzeppelin-contract/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin-contract/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ORAStakeRouter} from "../src/ORAStakeRouter.sol";
import {IORAStakeRouter} from "../src/interfaces/IORAStakeRouter.sol";

contract UpgradeORAStakeRouterScript is Script {
    address public proxyAdminAddress = 0x076CF237f609de0066AbC0974673Ab376992E4D2; // Replace with actual Proxy Admin address
    address public routerProxyAddress = 0x802b194E03E72c6104211CafcdAd376a56f0C974; // Replace with actual Router Proxy address

    address public ethPoolAddress = 0x5dCbD7057a974c07323dE7fe5347806d9De2ea1A;
    address public stETHPoolAddress = 0x1d9E08207Fa27b422db46581f04250544919774f;
    address public stakestonePoolAddress = 0xB3602C0513BE1EeADB4e53a70af9b623c68c4F83;

    address public olmPoolAddress = 0x2c791ad1F1A6704746E0C42b82FC889A4fb175D1;
    address public newImplementationAddress;

    function run() public {
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(routerProxyAddress);

        vm.startBroadcast();

        // Deploy new implementation
        ORAStakeRouter newRouterImpl = new ORAStakeRouter();
        newImplementationAddress = address(newRouterImpl);

        // Upgrade to new implementation
        proxyAdmin.upgrade(proxy, newImplementationAddress);

        //optional: fix existing data
        // IORAStakeRouter(routerProxyAddress).updatePool(ethPoolAddress, 1);
        // IORAStakeRouter(routerProxyAddress).updatePool(stETHPoolAddress, 1);
        // IORAStakeRouter(routerProxyAddress).updatePool(stakestonePoolAddress, 1);
        // IORAStakeRouter(routerProxyAddress).updatePool(olmPoolAddress, 2);
        vm.stopBroadcast();

        logAddress("ROUTER_IMPLEMENTATION_ADDR", address(newImplementationAddress));
        logAddress("ROUTER_PROXY_ADDR", routerProxyAddress);
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
