// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IORAStakePoolPermit {
    // **************** Write Functions  ****************
    function stakeWithPermit(
        address user,
        uint256 olmAmount,
        uint256 allowance,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
