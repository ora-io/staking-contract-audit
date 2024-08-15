// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin-contract/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin-contract/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ORAStakeRouter} from "../src/ORAStakeRouter.sol";
import {ORAStakePool_USDC} from "../src/ORAStakePool_USDC.sol";
import {ORAStakePool_USDT} from "../src/ORAStakePool_USDT.sol";
import {ORAStakePool_OLM} from "../src/ORAStakePool_OLM.sol";
import {MyToken} from "../src/mock/MockERC20Upgradeable.sol";

contract DeployScript is Script {
    address constant proxyAdmin = 0x2d1b035CA47E04A119dff0FAC828f4a57A67E4dE;
    address constant router_proxy = 0x784fDeBfD4779579B4cc2bac484129D29200412a;

    address constant olm_oldpool_proxy = 0x4F5E12233Ed7ca1699894174fCbD77c7eD60b03d;

    address constant olm_proxy = 0xe5018913F2fdf33971864804dDB5fcA25C539032;
    
    uint256 constant olm_vaultTVL = 3 * 1e26;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant swap_router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    uint256 constant usd_vaultTVL = 1e12;
    address constant usdc_proxy = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant usdt_proxy = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address constant permit2_proxy = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    bool constant initAsUnpause = false;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address initialOwner = msg.sender;
        // init OLM pool
        ORAStakePool_OLM olmpool_impl = new ORAStakePool_OLM();
        TransparentUpgradeableProxy olmpool_proxy =
            new TransparentUpgradeableProxy(address(olmpool_impl), proxyAdmin, new bytes(0));

        ORAStakePool_OLM(payable(address(olmpool_proxy))).initialize(
            router_proxy, initialOwner, "Liquidity ORA Token - OLM 2.0", "LOT-OLM2"
        );
        ORAStakePool_OLM(payable(address(olmpool_proxy))).setStakingTokenAddress(payable(address(olm_proxy)));
        ORAStakePool_OLM(payable(address(olmpool_proxy))).setWETHAddress(WETH);
        ORAStakePool_OLM(payable(address(olmpool_proxy))).setSwapRouterAddress(swap_router);

        // set OLM related vault
        address[] memory vaultPools = new address[](1);
        vaultPools[0] = address(olmpool_proxy);
        ORAStakeRouter(router_proxy).addVault(vaultPools, olm_vaultTVL);

        // set migration map
        ORAStakeRouter(router_proxy).setPoolMigrationAddress(olm_oldpool_proxy, address(olmpool_proxy));

        // init usdc pool
        //ORAStakePool_USDC usdcpool_impl = new ORAStakePool_USDC();
        address usdcpool_impl = 0x43F1a59f4c06Ad4866bDF985a05da43245Ca4633;
        TransparentUpgradeableProxy usdcpool_proxy =
            new TransparentUpgradeableProxy(address(usdcpool_impl), proxyAdmin, new bytes(0));

        ORAStakePool_USDC(payable(address(usdcpool_proxy))).initialize(
            router_proxy, initialOwner, "Liquidity ORA Token - USDC", "LOT-USDC"
        );
        ORAStakePool_USDC(payable(address(usdcpool_proxy))).setStakingTokenAddress(
            payable(address(usdc_proxy))
        );

        ORAStakePool_USDC(payable(address(usdcpool_proxy))).setPermit2Address(
            permit2_proxy
        );

        //init usdt pool
        ORAStakePool_USDT usdtpool_impl = new ORAStakePool_USDT();
        TransparentUpgradeableProxy usdtpool_proxy =
            new TransparentUpgradeableProxy(address(usdtpool_impl), proxyAdmin, new bytes(0));

        ORAStakePool_USDT(payable(address(usdtpool_proxy))).initialize(
            router_proxy, initialOwner, "Liquidity ORA Token - USDT", "LOT-USDT"
        );
        ORAStakePool_USDT(payable(address(usdtpool_proxy))).setStakingTokenAddress(
            payable(address(usdt_proxy))
        );
        ORAStakePool_USDT(payable(address(usdtpool_proxy))).setPermit2Address(
            permit2_proxy
        );


        // set USDT related vault
        address[] memory vault2Pools = new address[](2);
        vault2Pools[0] = address(usdcpool_proxy);
        vault2Pools[1] = address(usdtpool_proxy);
        ORAStakeRouter(router_proxy).addVault(vault2Pools, usd_vaultTVL);

        vm.stopBroadcast();
        logAddress("PROXY_ADMIN_ADDR", proxyAdmin);
        logAddress("ROUTER_OROXY_ADDR", router_proxy);
        logAddress("OLMTOKEN_PROXY_ADDR", address(olm_proxy));
        //logAddress("OLM_POOL2_PROXY_ADDR", address(olmpool_proxy));
        logAddress("USDC_TOKEN_ADDR", address(usdc_proxy));
        logAddress("USDT_TOKEN_ADDR", address(usdt_proxy));
        logAddress("USDC_POOL_ADDR", address(usdcpool_proxy));
        logAddress("USDT_POOL_ADDR", address(usdtpool_proxy));
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
