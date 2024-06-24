// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";
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
import {IORAStakeRouter} from "../src/interfaces/IORAStakeRouter.sol";

contract WithdrawTest is Test {
    ORAStakeRouter router;
    My7641Token olmToken;
    ORAStakePool_ETH ethPool;
    ORAStakePool_OLM olmPool;

    function setUp() public {
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        address initialOwner = address(this); // or specify a different owner address

        // init router
        ORAStakeRouter router_impl = new ORAStakeRouter();
        TransparentUpgradeableProxy router_proxy =
            new TransparentUpgradeableProxy(address(router_impl), address(proxyAdmin), new bytes(0));

        router = ORAStakeRouter(address(router_proxy));
        router.initialize(initialOwner);

        // init eth pool
        ORAStakePool_ETH ethpool_impl = new ORAStakePool_ETH();
        TransparentUpgradeableProxy ethpool_proxy =
            new TransparentUpgradeableProxy(address(ethpool_impl), address(proxyAdmin), new bytes(0));

        ethPool = ORAStakePool_ETH(address(ethpool_proxy));
        ethPool.initialize(address(router_proxy), initialOwner);
        ethPool.unpause();

        // set eth related vault
        address[] memory vaultPools = new address[](1);
        vaultPools[0] = address(ethpool_proxy);
        ORAStakeRouter(address(router_proxy)).addVault(vaultPools, 100 * 10 ** 18);
        ORAStakeRouter(address(router_proxy)).unpause();
        My7641Token olmToken_impl = new My7641Token();

        TransparentUpgradeableProxy olmToken_proxy =
            new TransparentUpgradeableProxy(address(olmToken_impl), address(proxyAdmin), new bytes(0));

        olmToken = My7641Token(payable(address(olmToken_proxy)));
        olmToken.initialize(initialOwner);

        ORAStakePool_OLM olmPool_impl = new ORAStakePool_OLM();
        TransparentUpgradeableProxy olmPool_proxy =
            new TransparentUpgradeableProxy(address(olmPool_impl), address(proxyAdmin), new bytes(0));

        olmPool = ORAStakePool_OLM(payable(address(olmPool_proxy)));
        olmPool.initialize(address(router_proxy), initialOwner, "OLM Stake", "S-OLM", 64800);
        olmPool.setStakingTokenAddress(address(olmToken));
        olmPool.unpause();

        address[] memory vaultPools2 = new address[](1);
        vaultPools2[0] = address(olmPool_proxy);
        ORAStakeRouter(address(router_proxy)).addVault(vaultPools2, 30 * 10 ** 18);
    }

    function testETHWithdraw() public {
        uint256 amount = 1e18; // 1 token for simplicity
        router.stake{value: amount}(address(ethPool), amount);
        router.requestWithdraw(address(ethPool), amount);

        IORAStakePool.WithdrawRequest[] memory result = router.getWithdrawQueue(address(ethPool), address(this));

        assertTrue(result.length > 0, "WithdrawRequest failed");
    }

    function testOLMWithdrawClaim() public {
        uint256 amount = 1e18; // 1 token for simplicity
        olmToken.mint(address(this), amount);
        olmToken.approve(address(olmPool), amount);

        // Stake tokens
        router.stake(address(olmPool), amount);
        router.requestWithdraw(address(olmPool), amount);
        router.getUserStakeAmountInPool(address(this), address(olmPool));

        // Get the current block timestamp
        uint256 currentTime = block.timestamp;

        // Warp time by 6 days, surpassing the 5 days grace period
        vm.warp(currentTime + 6 days);

        // Claim the withdrawal using the router
        router.claimWithdraw(address(olmPool));

        // Optionally, check the internal state to ensure the withdrawal is marked as claimed
        (uint256 claimableAmount, uint256 pendingAmount) = router.withdrawStatus(address(olmPool));
        assertEq(claimableAmount, 0, "There should be no claimable amount left");
        assertEq(pendingAmount, 0, "There should be no pending amount left");

        console.log("Withdrawal claimed successfully.");
    }
}
