// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";

contract ORAStakePool_ETH is ORAStakePoolBase {
    function _tokenTransferIn(address, uint256 amount) internal override {
        require(msg.value == amount, "mismatched staking amount");
    }

    function _tokenTransferOut(address user, uint256 amount) internal override {
        (bool success,) = payable(user).call{value: amount}("");
        require(success, "transfer failed");
    }
}
