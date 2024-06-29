// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IORAStakePoolPermit2} from "./interfaces/IORAStakePoolPermit2.sol";
import {ISignatureTransfer} from "./interfaces/ISignatureTransfer.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ORAStakePool_StakeStoneETH is ORAStakePoolBase, IORAStakePoolPermit2 {
    using Math for uint256;

    // **************** Permit2 Token Transfer  ****************
    function stakeWithPermit2(
        ISignatureTransfer.PermitTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        address user,
        bytes calldata signature
    ) external onlyRouter {
        require(permit.permitted.token == stakingTokenAddress, "token address mismatched.");
        _deposit(permit, transferDetails, user, signature);
    }

    function _deposit(
        ISignatureTransfer.PermitTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        address user,
        bytes calldata signature
    ) internal {
        uint256 shares = transferDetails.requestedAmount;
        if (totalAssets() != 0) {
            shares = _convertToShares(transferDetails.requestedAmount, Math.Rounding.Floor);
        }

        _mint(user, shares);
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
}
