// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {ORAStakePool_StETH} from "../src/ORAStakePool_STETH.sol";
import {ORAStakePool_StakeStoneETH} from "../src/ORAStakePool_StakeStoneETH.sol";
import {ORAStakePool_ETH} from "../src/ORAStakePool_ETH.sol";
import {ORAStakePool_OLM} from "../src/ORAStakePool_OLM.sol";
import {ORAStakeRouter} from "../src/ORAStakeRouter.sol";
contract PauseScript is Script {

    address public ethPoolAddress = 0x30CA6c5bc35cddE12bB0f3E4198C01ed2D6857f0;
    address public stETHPoolAddress = 0x30e1bFA947A7161Fce423056394B7e537199964c;
    address public stakestonePoolAddress = 0x0D563e769409902e4f7B45a8EE00AA44F8344A88;
    address public olmPoolAddress = 0x7be1D0C1641E5FDD55f4b3D682Fe21Da2963fE2b;
    address public routerAddress = 0x9D5B5855A2cadF30a1009F704aF07deBF71B5F4a;

    bool toPauseStake = false;
    bool toPauseWithdraw = false;

    function run() public {
        vm.startBroadcast();

        if(toPauseStake) {
            ORAStakePool_StakeStoneETH(stakestonePoolAddress).pause();
            ORAStakePool_StETH(stETHPoolAddress).pause();
            ORAStakePool_ETH(ethPoolAddress).pause();
            ORAStakePool_OLM(payable(olmPoolAddress)).pause();
            ORAStakeRouter(routerAddress).pause();
        } else {
            ORAStakePool_StakeStoneETH(stakestonePoolAddress).unpause();
            ORAStakePool_StETH(stETHPoolAddress).unpause();
            ORAStakePool_ETH(ethPoolAddress).unpause();
            ORAStakePool_OLM(payable(olmPoolAddress)).unpause();
            ORAStakeRouter(routerAddress).unpause();
        }

        ORAStakePool_StakeStoneETH(stakestonePoolAddress).setPauseWithdraw(toPauseWithdraw);
        ORAStakePool_StETH(stETHPoolAddress).setPauseWithdraw(toPauseWithdraw);
        ORAStakePool_ETH(ethPoolAddress).setPauseWithdraw(toPauseWithdraw);
        ORAStakePool_OLM(payable(olmPoolAddress)).setPauseWithdraw(toPauseWithdraw);
        ORAStakeRouter(routerAddress).setPauseWithdraw(toPauseWithdraw);

        vm.stopBroadcast();
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
