// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin-contract/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin-contract/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ORAStakeRouter} from "../src/ORAStakeRouter.sol";
import {ORAStakePool_OLM} from "../src/ORAStakePool_OLM.sol";

contract DeployScript is Script {
    address constant proxyAdmin = 0x076CF237f609de0066AbC0974673Ab376992E4D2;
    address constant router_proxy = 0x27005E147C856839eC135ad9FD329828Eb5b53b6;
    address constant olm_proxy = 0x0e919a5F1A28b1Bb8a92c4A1A8972F2e447DFAa2;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address initialOwner = msg.sender; // or specify a different owner address

        // init OLM token
        // My7641Token olm_impl = new My7641Token();

        // TransparentUpgradeableProxy olm_proxy =
        //     new TransparentUpgradeableProxy(address(olm_impl), proxyAdmin, new bytes(0));

        // My7641Token(payable(address(olm_proxy))).initialize(initialOwner);

        // init OLM pool
        ORAStakePool_OLM olmpool_impl = new ORAStakePool_OLM();
        TransparentUpgradeableProxy olmpool_proxy =
            new TransparentUpgradeableProxy(address(olmpool_impl), proxyAdmin, new bytes(0));

        ORAStakePool_OLM(payable(address(olmpool_proxy))).initialize(router_proxy, initialOwner);
        ORAStakePool_OLM(payable(address(olmpool_proxy))).setStakingTokenAddress(payable(address(olm_proxy)));

        // set OLM related vault
        address[] memory vaultPools = new address[](1);
        vaultPools[0] = address(olmpool_proxy);
        ORAStakeRouter(router_proxy).addVault(vaultPools, 30 * 10 ** 18);

        vm.stopBroadcast();
        logAddress("PROXY_ADMIN_ADDR", proxyAdmin);
        logAddress("ROUTER_OROXY_ADDR", router_proxy);
        logAddress("MOCKOLMTOKEN_PROXY_ADDR", address(olm_proxy));
        logAddress("OLM_POOL_PROXY_ADDR", address(olmpool_proxy));
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
