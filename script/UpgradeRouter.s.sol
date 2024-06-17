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
    address public routerProxyAddress = 0x679B8D145812237F7e01d966770b142a946963E2; // Replace with actual Router Proxy address

    address public ethPoolAddress = 0xB77Fc2ee5FC04465C2719A0055542ed8cE8611E0;
    address public stETHPoolAddress = 0x2Ed364335E0ef6308D86b96F28c9151bB7ccE11F;
    address public stakestonePoolAddress = 0x5a9167D96c5Ad4fd97F86263cA583C3bC7ef2F34;

    address public olmPoolAddress = 0xA18187Ca69F075AAA59F17742803b988E9996d04;
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
