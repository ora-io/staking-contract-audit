// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAllowanceTransfer} from "./IAllowanceTransfer.sol";

interface IORAStakePoolPermit2 {
    // **************** Write Functions  ****************
    function stakeWithPermit2(
        address user,
        IAllowanceTransfer.PermitSingle memory permitSingle,
        bytes calldata signature
    ) external;
}
