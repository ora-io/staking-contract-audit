// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IAllowanceTransfer} from "./interfaces/IAllowanceTransfer.sol";

contract ORAStakePool_StakeStoneETH is ORAStakePoolBase {
    address public stakestoneETH;
    address public permit2Address;

    modifier tokenAddressIsValid(address tokenAddress) {
        require(tokenAddress != address(0), "invalid token address");
        _;
    }

    function setStakeStoneETH(address _tokenAddress) external onlyOwner tokenAddressIsValid(_tokenAddress) {
        stakestoneETH = _tokenAddress;
    }

    function setPermit2Address(address _permit2Address) external onlyOwner tokenAddressIsValid(_permit2Address) {
        permit2Address = _permit2Address;
    }

    function _tokenTransferIn(address user, uint256 stakeAmount) internal override tokenAddressIsValid(stakestoneETH) tokenAddressIsValid(permit2Address)  {
        require(msg.value == 0, "eth amount should be 0.");

        IAllowanceTransfer(permit2Address).transferFrom(user, address(this), uint160(stakeAmount), stakestoneETH);
    }

    function _tokenTransferOut(address user, uint256 withdrawAmount) internal override tokenAddressIsValid(stakestoneETH) {
        IERC20(stakestoneETH).transfer(user, withdrawAmount);
    }
}
