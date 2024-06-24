// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IStETH} from "./interfaces/IStETH.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IORAStakePoolPermit} from "./interfaces/IORAStakePoolPermit.sol";

contract ORAStakePool_StETH is ORAStakePoolBase, IORAStakePoolPermit {
    // ******** Permit ************
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

    function _deposit(address user, uint256 amount) internal override {
        uint256 shares = IStETH(stakingTokenAddress).getSharesByPooledEth(amount);
        // convert amount to to shares
        _mint(user, shares);
        totalValueLocked += shares;
        _tokenTransferIn(user, amount);
    }

    function _withdraw(address user, uint256 shares) internal override {
        require(shares <= balanceOf(user), "invalid withdraw request");

        if (shares > 0) {
            uint256 amount = IStETH(stakingTokenAddress).getPooledEthByShares(shares);
            _burn(user, shares);
            totalValueLocked -= shares;
            _tokenTransferOut(user, amount);
        }
    }

    // ******** Token Transfer ************
    function _tokenTransferIn(address user, uint256 stakeAmount)
        internal
        override
        tokenAddressIsValid(stakingTokenAddress)
    {
        require(msg.value == 0, "eth amount should be 0.");

        IStETH(stakingTokenAddress).transferFrom(user, address(this), stakeAmount);
    }

    function _tokenTransferOut(address user, uint256 withdrawAmount)
        internal
        override
        tokenAddressIsValid(stakingTokenAddress)
    {
        IStETH(stakingTokenAddress).transfer(user, withdrawAmount);
    }
}
