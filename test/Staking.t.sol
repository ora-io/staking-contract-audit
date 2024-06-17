// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin-contract/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin-contract/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {MyToken} from "../src/mock/MockERC20Upgradeable.sol";
import {My7641Token} from "../src/mock/MockERC7641Upgradeable.sol";
import {ORAStakeRouter} from "../src/ORAStakeRouter.sol";
import {ORAStakePool_StETH} from "../src/ORAStakePool_STETH.sol";
import {ORAStakePool_StakeStoneETH} from "../src/ORAStakePool_StakeStoneETH.sol";
import {ORAStakePool_ETH} from "../src/ORAStakePool_ETH.sol";
import {ORAStakePool_OLM} from "../src/ORAStakePool_OLM.sol";

import {IORAStakePool} from "../src/interfaces/IORAStakePool.sol";

contract StakingTest is Test {
    ORAStakeRouter router;
    MyToken stETH;
    MyToken stakeStoneETH;
    My7641Token olmToken;
    ORAStakePool_ETH ethPool;
    ORAStakePool_StETH stEthPool;
    ORAStakePool_StakeStoneETH stakeStoneEthPool;
    ORAStakePool_OLM olmPool;

    function setUp() public {
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        address initialOwner = address(this); // or specify a different owner address

        // init steth token
        MyToken steth_impl = new MyToken();

        TransparentUpgradeableProxy steth_proxy =
            new TransparentUpgradeableProxy(address(steth_impl), address(proxyAdmin), new bytes(0));

        stETH = MyToken(address(steth_proxy));
        stETH.initialize("StETH", "LIDO StETH Mock", initialOwner);
        // init router
        ORAStakeRouter router_impl = new ORAStakeRouter();
        TransparentUpgradeableProxy router_proxy =
            new TransparentUpgradeableProxy(address(router_impl), address(proxyAdmin), new bytes(0));

        router = ORAStakeRouter(address(router_proxy));
        router.initialize(initialOwner);
        router.unpause();
        // init steth pool
        ORAStakePool_StETH stpool_impl = new ORAStakePool_StETH();
        TransparentUpgradeableProxy stpool_proxy =
            new TransparentUpgradeableProxy(address(stpool_impl), address(proxyAdmin), new bytes(0));

        stEthPool = ORAStakePool_StETH(address(stpool_proxy));
        stEthPool.initialize(address(router_proxy), initialOwner);
        stEthPool.setStakingTokenAddress(address(steth_proxy));
        stEthPool.unpause();
        // init stakestone token
        MyToken stakestoneeth_impl = new MyToken();

        TransparentUpgradeableProxy stakestoneeth_proxy =
            new TransparentUpgradeableProxy(address(stakestoneeth_impl), address(proxyAdmin), new bytes(0));

        stakeStoneETH = MyToken(address(stakestoneeth_proxy));
        stakeStoneETH.initialize("StakeStone", "Stakestone ETH Mock", initialOwner);

        // init stakestone pool
        ORAStakePool_StakeStoneETH stakestonepool_impl = new ORAStakePool_StakeStoneETH();
        TransparentUpgradeableProxy stakestonepool_proxy =
            new TransparentUpgradeableProxy(address(stakestonepool_impl), address(proxyAdmin), new bytes(0));

        stakeStoneEthPool = ORAStakePool_StakeStoneETH(address(stakestonepool_proxy));
        stakeStoneEthPool.initialize(address(router_proxy), initialOwner);
        stakeStoneEthPool.setStakingTokenAddress(address(stakestoneeth_proxy));
        stakeStoneEthPool.unpause();
        // init eth pool
        ORAStakePool_ETH ethpool_impl = new ORAStakePool_ETH();
        TransparentUpgradeableProxy ethpool_proxy =
            new TransparentUpgradeableProxy(address(ethpool_impl), address(proxyAdmin), new bytes(0));

        ethPool = ORAStakePool_ETH(address(ethpool_proxy));
        ethPool.initialize(address(router_proxy), initialOwner);
        ethPool.unpause();

        // set eth related vault
        address[] memory vaultPools = new address[](3);
        vaultPools[0] = address(stpool_proxy);
        vaultPools[1] = address(stakeStoneEthPool);
        vaultPools[2] = address(ethpool_proxy);
        ORAStakeRouter(address(router_proxy)).addVault(vaultPools, 100 * 10 ** 18);
    }

    function testStakestoneETHStaking() public {
        uint256 amount = 1e18; // 1 token for simplicity
        stakeStoneETH.mint(address(this), amount);
        stakeStoneETH.approve(address(stakeStoneEthPool), amount);
        router.stake(address(stakeStoneEthPool), amount);

        assertTrue(stakeStoneEthPool.balanceOf(address(this)) == amount, "Staking failed");
    }

    function testStETHStaking() public {
        uint256 amount = 1e18; // 1 token for simplicity
        stETH.mint(address(this), amount);
        stETH.approve(address(stEthPool), amount);
        router.stake(address(stEthPool), amount);

        assertTrue(stEthPool.balanceOf(address(this)) == amount, "Staking failed");
    }

    function testETHStaking() public {
        uint256 amount = 1e18; // 1 token for simplicity
        router.stake{value: amount}(address(ethPool), amount);

        assertTrue(ethPool.balanceOf(address(this)) == amount, "Staking failed");
    }
}
