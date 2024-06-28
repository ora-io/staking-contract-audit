// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";
import {IORAStakePoolPermit} from "./interfaces/IORAStakePoolPermit.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract ORAStakePoolPermit is ORAStakePoolBase, IORAStakePoolPermit {
    function stakeWithPermit(
        address user,
        uint256 stETHAmount,
        uint256 allowance,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyRouter {
        if (IERC20(stakingTokenAddress).allowance(user, address(this)) < stETHAmount) {
            IERC20Permit(stakingTokenAddress).permit(user, address(this), allowance, deadline, v, r, s);
        }
        _deposit(user, stETHAmount);
    }
}
