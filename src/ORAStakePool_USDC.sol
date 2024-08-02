// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IORAStakePoolPermit2} from "./interfaces/IORAStakePoolPermit2.sol";
import {IAllowanceTransfer} from "./interfaces/IAllowanceTransfer.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ORAStakePool_USDC is ORAStakePoolBase, IORAStakePoolPermit2 {
    using Math for uint256;

    // **************** Permit2 Token Transfer  ****************
    function stakeWithPermit2(
        address user,
        IAllowanceTransfer.PermitSingle calldata permitSingle,
        bytes calldata signature
    ) external onlyRouter whenNotPaused {
        require(permitSingle.details.token == stakingTokenAddress, "token address mismatched.");
        require(permitSingle.spender == address(this), "receiving address mismatched.");

        // check if permit2 has enough allowance for this contract
        (uint160 amount, uint48 exp,) =
            IAllowanceTransfer(permit2Address).allowance(user, permitSingle.details.token, address(this));

        if (amount < permitSingle.details.amount || exp < block.timestamp) {
            IAllowanceTransfer(permit2Address).permit(user, permitSingle, signature);
        }
        _deposit(user, permitSingle);
    }

    function _deposit(address user, IAllowanceTransfer.PermitSingle calldata permitSingle) internal {
        uint256 shares = _convertToShares(permitSingle.details.amount, Math.Rounding.Floor, 0, false);

        _mint(user, shares);
        _tokenTransferIn(user, permitSingle);
    }

    // ******** Token Transfer ************
    function _tokenTransferIn(address user, IAllowanceTransfer.PermitSingle calldata permitSingle) internal {
        require(msg.value == 0, "eth amount should be 0.");

        IAllowanceTransfer(permit2Address).transferFrom(
            user, address(this), permitSingle.details.amount, stakingTokenAddress
        );
    }
}
