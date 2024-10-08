// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IORAStakePool} from "./IORAStakePool.sol";
import {IAllowanceTransfer} from "./IAllowanceTransfer.sol";

interface IORAStakeRouter {
    // ******** Structures ************
    struct PoolVault {
        address[] pools;
        uint256 maxTVL;
    }

    // **************** Write Functions  ****************
    function stake(address pool, uint256 amount) external payable;
    function stake(address pool, uint256 amount, uint256 allowance, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
    function stake(address pool, IAllowanceTransfer.PermitSingle calldata permitSingle, bytes calldata signature)
        external;
    function requestWithdraw(address pool, uint256 amount) external returns (address, uint256 requestId);
    function claimWithdraw(address pool) external;
    function claimWithdraw(address[] calldata pools) external;
    function getVaultCurrentTVL(uint256 vaultID) external returns (uint256);

    // **************** Read Functions ******************
    function withdrawStatus(address pool) external view returns (uint256, uint256);
    function getVaultMaxTVL(uint256 vaultID) external view returns (uint256);
    function getPoolTVL(address pool) external view returns (uint256);
    function getWithdrawQueue(address pool, address user)
        external
        view
        returns (IORAStakePool.WithdrawRequest[] memory);
    function getUserStakeAmount(address user, uint256 vaultID) external view returns (uint256);
    function getUserStakeAmountInPool(address user, address pool) external view returns (uint256 stakeAmount);

    // **************** Admin Functions *****************
    function addVault(address[] calldata pools, uint256 maxTVL) external;
    function updateVault(uint256 vaultID, uint256 maxTVL) external;
    function updatePool(address pool, uint256 vaultID) external;
    function removePool(address pool) external;
    function setPauseWithdraw(bool pauseWithdrawRq) external;
    function updateWithdrawGracePeriod(uint256 _newPeriod) external;
    function withdrawGracePeriod() external view returns (uint256);

    // ******** Events ************
    event NewVault(uint256 indexed vaultID, uint256 maxTVL);
    event Stake(address indexed user, uint256 indexed amount, address indexed pool, uint256 vaultId);
    event RequestWithdraw(
        address indexed user, uint256 indexed amount, address indexed pool, uint256 vaultId, uint256 requestID
    );
    event ClaimWithdraw(
        address indexed user, uint256 indexed amount, address indexed pool, uint256 vaultId, uint256 lastRequestID
    );
    // ******** Errors ************

    error ExceedingTVL();
}
