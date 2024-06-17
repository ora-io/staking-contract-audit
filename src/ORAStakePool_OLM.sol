// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase_ERC7641} from "./ORAStakePoolBase_ERC7641.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC7641} from "./interfaces/IERC7641.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IAllowanceTransfer} from "./interfaces/IAllowanceTransfer.sol";
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
    ) external {
        IERC20Permit(stakingTokenAddress).permit(user, address(this), allowance, deadline, v, r, s);
        _deposit(user, olmAmount);
    }

    // ******** Token Transfer ************
    function _tokenTransferIn(address user, uint256 stakeAmount)
        internal
        override
        tokenAddressIsValid(stakingTokenAddress)
    {
        require(msg.value == 0, "eth amount should be 0.");
        if (permit2Address != address(0)) {
            IAllowanceTransfer(permit2Address).transferFrom(
                user, address(this), uint160(stakeAmount), stakingTokenAddress
            );
        } else {
            IERC20(stakingTokenAddress).transferFrom(user, address(this), stakeAmount);
        }
    }

    function _tokenTransferOut(address user, uint256 withdrawAmount)
        internal
        override
        tokenAddressIsValid(stakingTokenAddress)
    {
        IERC20(stakingTokenAddress).transfer(user, withdrawAmount);
    }
}
