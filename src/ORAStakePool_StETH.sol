// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";
import {IStETH} from "./interfaces/IStETH.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract ORAStakePool_StETH is ORAStakePoolBase {
    address public stETH;

    modifier tokenAddressIsValid(address tokenAddress) {
        require(tokenAddress != address(0), "invalid token address");
        _;
    }

    function setStETH(address _tokenAddress) external onlyOwner tokenAddressIsValid(_tokenAddress) {
        stETH = _tokenAddress;
    }

    function stakeWithPermit(
        address user,
        uint256 stETHAmount,
        uint256 allowance,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20Permit(stETH).permit(user, address(this), allowance, deadline, v, r, s);
        _deposit(user, stETHAmount);
    }

    function _tokenTransferIn(address user, uint256 stakeAmount) internal override tokenAddressIsValid(stETH) {
        require(msg.value == 0, "eth amount should be 0.");

        IStETH(stETH).transferFrom(user, address(this), IStETH(stETH).getSharesByPooledEth(stakeAmount));
    }

    function _tokenTransferOut(address user, uint256 withdrawAmount) internal override tokenAddressIsValid(stETH) {
        IStETH(stETH).transfer(user, withdrawAmount);
    }
}
