// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IORAStakeRouter} from "./interfaces/IORAStakeRouter.sol";
import {IORAStakePool} from "./interfaces/IORAStakePool.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ORAStakeRouter is OwnableUpgradeable, PausableUpgradeable, IORAStakeRouter {
    using Math for uint256;

    uint256 private constant MULTIPLIER = 10 ** 18;
    uint256 private constant TOTAL_VALUE_LOCKED_LIMIT = 100 * MULTIPLIER;
    uint256 private constant SECONDS_ONE_DAY = 86400;
    uint256 public withdrawGracePeriod;
    bool public pauseWithdraw = false;
    PoolVault[] public vaults; // id starts from 1
    mapping(address => uint256) public pool2VaultId;

    modifier validVaultIdOnly(uint256 vaultId) {
        require(vaultId != 0 && vaultId < vaults.length, "Vault ID does not exist.");
        _;
    }

    modifier validPoolOnly(address pool) {
        require(pool2VaultId[pool] != 0, "Pool does not exist");
        _;
    }

    modifier isWithdrawAllowed() {
        require(pauseWithdraw == false, "withdraw is paused.");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) external initializer {
        __Ownable_init(_owner);
        __Pausable_init();
        _pause();

        // initiate the vaults array
        PoolVault memory initVault = PoolVault(new address[](0), 0, 0);
        vaults.push(initVault);

        withdrawGracePeriod = SECONDS_ONE_DAY; // 1 day by default
    }

    // **************** Write Functions  ****************
    function stake(address pool, uint256 amount) external payable validPoolOnly(pool) whenNotPaused {
        require(amount > 0, "invalid staking amount.");
        PoolVault storage targetVault = vaults[pool2VaultId[pool]];
        if (targetVault.currentTVL + amount > targetVault.maxTVL) {
            revert ExceedingTVL();
        }
        IORAStakePool(pool).stake{value: msg.value}(msg.sender, amount);
        targetVault.currentTVL += amount;

        emit Stake(msg.sender, amount, pool2VaultId[pool], pool);
    }

    function requestWithdraw(address pool, uint256 amount)
        external
        validPoolOnly(pool)
        isWithdrawAllowed
        returns (address, uint256 requestId)
    {
        require(amount > 0, "invalid withdraw amount.");

        requestId = IORAStakePool(pool).requestWithdraw(msg.sender, amount);

        emit RequestWithdraw(msg.sender, amount, requestId);
        return (pool, requestId);
    }

    function claimWithdraw(address pool) external validPoolOnly(pool) {
        PoolVault storage targetVault = vaults[pool2VaultId[pool]];
        uint256 amount = IORAStakePool(pool).claimWithdraw(msg.sender);

        targetVault.currentTVL -= amount;
        emit ClaimWithdraw(msg.sender, amount, pool2VaultId[pool], pool);
    }

    function claimWithdraw(address[] calldata pools) external {
        // This function would need to know which pool the requestIDs belong to, which is not provided in the interface.
        for (uint256 i = 0; i < pools.length; i++) {
            PoolVault storage targetVault = vaults[pool2VaultId[pools[i]]];

            uint256 amount = IORAStakePool(pools[i]).claimWithdraw(msg.sender);
            targetVault.currentTVL -= amount;
            emit ClaimWithdraw(msg.sender, amount, pool2VaultId[pools[i]], pools[i]);
        }
    }

    function syncTVL(uint256 vaultId) external validVaultIdOnly(vaultId) {
        require(vaultId != 0 && vaultId < vaults.length, "Vault ID does not exist.");
        uint256 totalTVL = 0;
        PoolVault storage targetVault = vaults[vaultId];
        for (uint256 i = 0; i < vaults[vaultId].pools.length; i++) {
            address pool = vaults[vaultId].pools[i];
            totalTVL += IORAStakePool(pool).currentTVL();
        }
        targetVault.currentTVL = totalTVL;
    }    

    // **************** Read Functions ******************
    function withdrawStatus(address pool) external view returns (uint256 claimableAmount, uint256 pendingAmount) {
        (claimableAmount, pendingAmount) = IORAStakePool(pool).withdrawStatus(msg.sender);
    }

    function getVaultTVL(uint256 vaultID) external view returns (uint256) {
        return vaults[vaultID].maxTVL;
    }

    function getPoolTVL(address pool) external view returns (uint256) {
        return IORAStakePool(pool).currentTVL();
    }

    function getWithdrawQueue(address pool, address user)
        external
        view
        returns (IORAStakePool.WithdrawRequest[] memory)
    {
        return IORAStakePool(pool).getWithdrawQueue(user);
    }

    function getUserStakeAmount(address user, uint256 vaultID) external view returns (uint256 stakeAmount) {
        require(vaultID < vaults.length, " invalid vault id");
        PoolVault storage currVault = vaults[vaultID];
        for (uint256 i = 0; i < currVault.pools.length; i++) {
            stakeAmount += getUserStakeAmountInPool(user, currVault.pools[i]);
        }
    }

    function getUserStakeAmountInPool(address user, address pool) public view returns (uint256 stakeAmount) {
        stakeAmount = IERC20(pool).balanceOf(user);
        (uint256 claimable, uint256 pending) = IORAStakePool(pool).withdrawStatus(user);
        stakeAmount -= claimable;
        stakeAmount -= pending;
    }

    // **************** Admin Functions *****************
    function addVault(address[] calldata pools, uint256 maxTVL) external onlyOwner {
        PoolVault memory newVault = PoolVault(pools, 0, maxTVL);
        vaults.push(newVault);
        for (uint256 i = 0; i < pools.length; i++) {
            pool2VaultId[pools[i]] = vaults.length - 1;
        }
    }

    function updateVault(uint256 vaultId, uint256 maxTVL) external onlyOwner validVaultIdOnly(vaultId) {
        vaults[vaultId].maxTVL = maxTVL;
    }

    function updatePool(address pool, uint256 vaultId) external onlyOwner validVaultIdOnly(vaultId) {
        require(pool2VaultId[pool] != vaultId, "Pool is already in the specified vault.");
        // Remove pool from old vault
        removePool(pool);
        // Add pool to new vault
        vaults[vaultId].pools.push(pool);
        pool2VaultId[pool] = vaultId;
    }

    function removePool(address pool) public onlyOwner validPoolOnly(pool) {
        uint256 vaultID = pool2VaultId[pool];

        address[] storage vaultPools = vaults[vaultID].pools;
        for (uint256 i = 0; i < vaultPools.length; i++) {
            if (vaultPools[i] == pool) {
                vaultPools[i] = vaultPools[vaultPools.length - 1];
                vaultPools.pop();
                break;
            }
        }
        delete pool2VaultId[pool];
    }

    function parseRequest(bool _pauseWithdrawRq) external onlyOwner {
        pauseWithdraw = _pauseWithdrawRq;
    }

    function updateWithdrawGracePeriod(uint256 _newPeriod) external onlyOwner {
        withdrawGracePeriod = _newPeriod;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
