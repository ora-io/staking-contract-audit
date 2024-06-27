// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase_ERC7641} from "./ORAStakePoolBase_ERC7641.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC7641} from "./interfaces/IERC7641.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IORAStakePoolPermit} from "./interfaces/IORAStakePoolPermit.sol";

contract ORAStakePool_OLM is ORAStakePoolBase_ERC7641, IORAStakePoolPermit {
    // ******** Permit ************
    function stakeWithPermit(
        address user,
        uint256 olmAmount,
        uint256 allowance,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyRouter {
        if (IERC20(stakingTokenAddress).allowance(user, address(this)) < olmAmount) {
            IERC20Permit(stakingTokenAddress).permit(user, address(this), allowance, deadline, v, r, s);
        }
        _deposit(user, olmAmount);
    }

    // ******** Token Transfer ************
    function _tokenTransferIn(address user, uint256 stakeAmount)
        internal
        override
        tokenAddressIsValid(stakingTokenAddress)
    {
        require(msg.value == 0, "eth amount should be 0.");
        IERC20(stakingTokenAddress).transferFrom(user, address(this), stakeAmount);
    }

    function _tokenTransferOut(address user, uint256 withdrawAmount)
        internal
        override
        tokenAddressIsValid(stakingTokenAddress)
    {
        IERC20(stakingTokenAddress).transfer(user, withdrawAmount);
    }

    function currentTVL() external view override returns (uint256) {
        return IERC20(stakingTokenAddress).balanceOf(address(this));
    }
}
