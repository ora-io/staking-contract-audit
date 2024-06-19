// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IORAStakePoolPermit2} from "./interfaces/IORAStakePoolPermit2.sol";
import {ISignatureTransfer} from "./interfaces/ISignatureTransfer.sol";

contract ORAStakePool_StakeStoneETH is ORAStakePoolBase, IORAStakePoolPermit2 {
    // **************** Permit2 Token Transfer  ****************
    function stakeWithPermit2(
        ISignatureTransfer.PermitTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        address user,
        bytes calldata signature
    ) external tokenAddressIsValid(permit2Address) {
        require(permit.permitted.token == stakingTokenAddress, "token address mismatched.");
        _deposit(permit, transferDetails, user, signature);
    }

    function _deposit(
        ISignatureTransfer.PermitTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        address user,
        bytes calldata signature
    ) internal {
        _mint(user, transferDetails.requestedAmount);
        totalValueLocked += transferDetails.requestedAmount;
        _tokenTransferIn(permit, transferDetails, user, signature);
    }

    // ******** Token Transfer ************
    function _tokenTransferIn(
        ISignatureTransfer.PermitTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        address user,
        bytes calldata signature
    ) internal tokenAddressIsValid(stakingTokenAddress) {
        require(msg.value == 0, "eth amount should be 0.");

        ISignatureTransfer(permit2Address).permitTransferFrom(permit, transferDetails, user, signature);
    }

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
}
