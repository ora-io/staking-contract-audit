// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin-contract/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin-contract/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ORAStakeRouter} from "../src/ORAStakeRouter.sol";
import {ORAStakePool_OLM} from "../src/ORAStakePool_OLM.sol";

contract DeployScript is Script {
    address constant proxyAdmin = 0x2d1b035CA47E04A119dff0FAC828f4a57A67E4dE;
    address constant router_proxy = 0x784fDeBfD4779579B4cc2bac484129D29200412a;
    address constant olm_proxy = 0xe5018913F2fdf33971864804dDB5fcA25C539032;
    uint256 constant olm_vaultTVL = 3*1e26;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant swap_router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    bool constant initAsUnpause = false;


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

        ORAStakePool_OLM(payable(address(olmpool_proxy))).initialize(
            router_proxy, initialOwner, "Liquidity ORA Token - OLM", "LOT-OLM"
        );
        ORAStakePool_OLM(payable(address(olmpool_proxy))).setStakingTokenAddress(payable(address(olm_proxy)));
        ORAStakePool_OLM(payable(address(olmpool_proxy))).setWETHAddress(WETH);
        ORAStakePool_OLM(payable(address(olmpool_proxy))).setSwapRouterAddress(swap_router);

        // set OLM related vault
        address[] memory vaultPools = new address[](1);
        vaultPools[0] = address(olmpool_proxy);
        ORAStakeRouter(router_proxy).addVault(vaultPools, olm_vaultTVL);

        if (initAsUnpause) {
            ORAStakePool_OLM(payable(address(olmpool_proxy))).unpause();
            ORAStakePool_OLM(payable(address(olmpool_proxy))).setPauseWithdraw(false);
        }

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
