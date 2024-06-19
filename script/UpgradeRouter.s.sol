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
    address public routerProxyAddress = 0x256a883AAcE1ff96B1C9CB5a3284285b6cacE11B; // Replace with actual Router Proxy address

    address public ethPoolAddress = 0xB311424b2DA6841EC532535b7fd2308c388Cdd1e;
    address public stETHPoolAddress = 0x8E1942cd8FBc91BCD44997E13De6E4fC06db2869;
    address public stakestonePoolAddress = 0x42069636D4a72AF50e35d2537423A359925903c8;

    address public olmPoolAddress = 0x07f836115552C85fc46144c8E93ede1ADA2E8111;
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
