// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IORAStakePool {

    // ******** Structures ************
    struct WithdrawRequest {
        uint256 amount;
        uint256 requestTimeStamp;
    }

    // **************** Write Functions  ****************
    function stake(address user, uint256 amount) external payable;
    function requestWithdraw(address user, uint256 amount) external returns (uint256 requestID);
    function claimWithdraw(address user) external returns (uint256 amount);

    // **************** Read Functions ******************
    function withdrawStatus(address user) external view returns (uint256 claimableAmount, uint256 pendingAmount);
    function currentTVL() external view returns (uint256);
    function getWithdrawQueue(address user) external view returns (WithdrawRequest[] memory queue);

    // **************** Admin Functions *****************
    function setStakingPoolRouter(address router) external;
    
    // ******** Errors ************
    error InvalidRequestId(uint256 requestId);
    error StakingNotInitiated();
}
