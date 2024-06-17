// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase_ERC7641} from "./ORAStakePoolBase_ERC7641.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC7641} from "./interfaces/IERC7641.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract ORAStakePool_OLM is ORAStakePoolBase_ERC7641 {
    address public OLMToken;

    modifier tokenAddressIsValid(address tokenAddress) {
        require(tokenAddress != address(0), "invalid token address");
        _;
    }
        
    // ******** Events ************
    event RevenueClaimed(uint256 indexed snapshotId);

    function setOLMTokenAddress(address _tokenAddress) external onlyOwner tokenAddressIsValid(_tokenAddress) {
        OLMToken = _tokenAddress;
    }

    function claimWithdraw(uint256 _snapshotId) external tokenAddressIsValid(OLMToken) {
        IERC7641(OLMToken).claim(_snapshotId);

        emit RevenueClaimed(_snapshotId);
    }

    function stakeWithPermit(
        address user,
        uint256 olmAmount,
        uint256 allowance,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20Permit(OLMToken).permit(user, address(this), allowance, deadline, v, r, s);
        _deposit(user, olmAmount);
    }

    function _tokenTransferIn(address user, uint256 stakeAmount) internal override tokenAddressIsValid(OLMToken) {
        require(msg.value == 0, "eth amount should be 0.");

        IERC20(OLMToken).transferFrom(user, address(this), stakeAmount);
    }

    function _tokenTransferOut(address user, uint256 withdrawAmount) internal override tokenAddressIsValid(OLMToken) {
        IERC20(OLMToken).transfer(user, withdrawAmount);
    }
}
