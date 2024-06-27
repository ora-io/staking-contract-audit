// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin-contract/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin-contract/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {MyToken} from "../src/mock/MockERC20Upgradeable.sol";
import {ORAStakeRouter} from "../src/ORAStakeRouter.sol";
import {ORAStakePool_StETH} from "../src/ORAStakePool_STETH.sol";
import {ORAStakePool_StakeStoneETH} from "../src/ORAStakePool_StakeStoneETH.sol";
import {ORAStakePool_ETH} from "../src/ORAStakePool_ETH.sol";
import {ORAStakePool_OLM} from "../src/ORAStakePool_OLM.sol";

contract DeployScript is Script {
    address constant steth_proxy = 0x5FeC619342077cdB90652205535DBFCa6a1126fC;
    address constant stakestoneeth_proxy = 0x2FC35F3B5B75ecF265756882Eb21c68FDcaa828d;
    address constant proxyAdminAddress = 0x076CF237f609de0066AbC0974673Ab376992E4D2;

    bool constant initAsUnpause = true;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // ProxyAdmin proxyAdmin = new ProxyAdmin();
        // logAddress("PROXY_ADMIN_ADDR", address(proxyAdmin));

        address initialOwner = msg.sender; // or specify a different owner address

        // init steth token
        // MyToken steth_impl = new MyToken();

        // TransparentUpgradeableProxy steth_proxy =
        //     new TransparentUpgradeableProxy(address(steth_impl), address(proxyAdmin), new bytes(0));

        // MyToken(address(steth_proxy)).initialize("StETH", "LIDO StETH Mock", initialOwner);

        // init router
        ORAStakeRouter router_impl = new ORAStakeRouter();
        TransparentUpgradeableProxy router_proxy =
            new TransparentUpgradeableProxy(address(router_impl), proxyAdminAddress, new bytes(0));

        ORAStakeRouter(address(router_proxy)).initialize(initialOwner);

        if (initAsUnpause) {
            ORAStakeRouter(address(router_proxy)).unpause();
        }

        // init steth pool
        ORAStakePool_StETH stpool_impl = new ORAStakePool_StETH();
        TransparentUpgradeableProxy stpool_proxy =
            new TransparentUpgradeableProxy(address(stpool_impl), proxyAdminAddress, new bytes(0));

        ORAStakePool_StETH(address(stpool_proxy)).initialize(address(router_proxy), initialOwner);
        ORAStakePool_StETH(address(stpool_proxy)).setStakingTokenAddress(address(steth_proxy));

        if (initAsUnpause) {
            ORAStakePool_StETH(address(stpool_proxy)).unpause();
        }

        // init stakestone token
        // MyToken stakestoneeth_impl = new MyToken();

        // TransparentUpgradeableProxy stakestoneeth_proxy =
        //     new TransparentUpgradeableProxy(address(stakestoneeth_impl), address(proxyAdmin), new bytes(0));

        // MyToken(address(stakestoneeth_proxy)).initialize("StakeStone", "Stakestone ETH Mock", initialOwner);

        // init stakestone pool
        ORAStakePool_StakeStoneETH stakestonepool_impl = new ORAStakePool_StakeStoneETH();
        TransparentUpgradeableProxy stakestonepool_proxy =
            new TransparentUpgradeableProxy(address(stakestonepool_impl), proxyAdminAddress, new bytes(0));

        ORAStakePool_StakeStoneETH(address(stakestonepool_proxy)).initialize(address(router_proxy), initialOwner);
        ORAStakePool_StakeStoneETH(address(stakestonepool_proxy)).setStakingTokenAddress(address(stakestoneeth_proxy));

        if (initAsUnpause) {
            ORAStakePool_StakeStoneETH(address(stakestonepool_proxy)).unpause();
        }

        // init eth pool
        ORAStakePool_ETH ethpool_impl = new ORAStakePool_ETH();
        TransparentUpgradeableProxy ethpool_proxy =
            new TransparentUpgradeableProxy(address(ethpool_impl), proxyAdminAddress, new bytes(0));

        ORAStakePool_ETH(address(ethpool_proxy)).initialize(address(router_proxy), initialOwner);

        if (initAsUnpause) {
            ORAStakePool_ETH(address(ethpool_proxy)).unpause();
        }

        // set eth related vault
        address[] memory vaultPools = new address[](3);
        vaultPools[0] = address(stpool_proxy);
        vaultPools[1] = address(stakestonepool_proxy);
        vaultPools[2] = address(ethpool_proxy);
        ORAStakeRouter(address(router_proxy)).addVault(vaultPools, 100 * 10 ** 18);

        ORAStakeRouter(address(router_proxy)).updateWithdrawGracePeriod(100);

        // init olm pool

        vm.stopBroadcast();
        logAddress("ROUTER_PROXY_ADDR", address(router_proxy));
        logAddress("STETH_PROXY_ADDR", address(steth_proxy));
        logAddress("STETHPOOL_PROXY_ADDR", address(stpool_proxy));
        logAddress("STAKESTONEETH_PROXY_ADDR", address(stakestoneeth_proxy));
        logAddress("STAKESTONEETHPOOL_PROXY_ADDR", address(stakestonepool_proxy));
        logAddress("ETHPOOL_PROXY_ADDR", address(ethpool_proxy));
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
