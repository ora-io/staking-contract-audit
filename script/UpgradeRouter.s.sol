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

    address public ethPoolAddress = 0xb2bA4FdBd74A10C01E06291E04c7Bbc8da05d4e3;
    address public stETHPoolAddress = 0xc632CcE23917C80191B2cE80DeF00D91C627932a;
    address public stakestonePoolAddress = 0x4e34818517Fb95eF8351E73665Ba90525A7815b2;

    address public olmPoolAddress = 0x565DCD06caF01F5320e0a76303FABeb8962D6eb7;
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
