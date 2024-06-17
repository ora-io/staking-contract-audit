// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IAllowanceTransfer} from "./interfaces/IAllowanceTransfer.sol";

contract ORAStakePool_StakeStoneETH is ORAStakePoolBase {

    function _tokenTransferIn(address user, uint256 stakeAmount) internal override tokenAddressIsValid(stakingTokenAddress) {
        require(msg.value == 0, "eth amount should be 0.");

        if(permit2Address != address(0)) {
            IAllowanceTransfer(permit2Address).transferFrom(user, address(this), uint160(stakeAmount), stakingTokenAddress);
        } else {
            IERC20(stakingTokenAddress).transferFrom(user, address(this), stakeAmount);
        }
    }

    function _tokenTransferOut(address user, uint256 withdrawAmount) internal override tokenAddressIsValid(stakingTokenAddress) {
        IERC20(stakingTokenAddress).transfer(user, withdrawAmount);
    }
}
