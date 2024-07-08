// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IORAStakeRouter} from "./interfaces/IORAStakeRouter.sol";
import {IORAStakePool} from "./interfaces/IORAStakePool.sol";
import {IORAStakePoolPermit} from "./interfaces/IORAStakePoolPermit.sol";
import {IORAStakePoolPermit2} from "./interfaces/IORAStakePoolPermit2.sol";
import {IAllowanceTransfer} from "./interfaces/IAllowanceTransfer.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ORAStakeRouter is OwnableUpgradeable, PausableUpgradeable, IORAStakeRouter {
    using Math for uint256;

    uint256 private constant MULTIPLIER = 10 ** 18;
    uint256 private constant TOTAL_VALUE_LOCKED_LIMIT = 100 * MULTIPLIER;
    uint256 private constant SECONDS_ONE_DAY = 86400;
    uint256 public withdrawGracePeriod;

    bool public pauseWithdraw;

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

    modifier whenNotPausedWithdraw() {
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
        PoolVault memory initVault = PoolVault(new address[](0), 0);
        vaults.push(initVault);

        withdrawGracePeriod = SECONDS_ONE_DAY; // 1 day by default
        _setPauseWithdraw(true);
    }

    // **************** Write Functions  ****************
    function stake(address pool, uint256 amount) external payable validPoolOnly(pool) whenNotPaused {
        _validateStake(pool, amount);

        IORAStakePool(pool).stake{value: msg.value}(msg.sender, amount);

        emit Stake(msg.sender, amount, pool2VaultId[pool], pool);
    }

    function stake(address pool, uint256 amount, uint256 allowance, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        validPoolOnly(pool)
        whenNotPaused
    {
        _validateStake(pool, amount);

        IORAStakePoolPermit(pool).stakeWithPermit(msg.sender, amount, allowance, deadline, v, r, s);

        emit Stake(msg.sender, amount, pool2VaultId[pool], pool);
    }

    function stake(address pool, IAllowanceTransfer.PermitSingle calldata permitSingle, bytes calldata signature)
        external
        validPoolOnly(pool)
        whenNotPaused
    {
        _validateStake(pool, permitSingle.details.amount);

        IORAStakePoolPermit2(pool).stakeWithPermit2(msg.sender, permitSingle, signature);

        emit Stake(msg.sender, permitSingle.details.amount, pool2VaultId[pool], pool);
    }

    function requestWithdraw(address pool, uint256 amount)
        external
        validPoolOnly(pool)
        whenNotPausedWithdraw
        returns (address, uint256 requestId)
    {
        require(amount > 0, "invalid withdraw amount.");

        requestId = IORAStakePool(pool).requestWithdraw(msg.sender, amount);

        emit RequestWithdraw(msg.sender, amount, requestId, pool);
        return (pool, requestId);
    }

    function claimWithdraw(address pool) external validPoolOnly(pool) {
        uint256 amount = IORAStakePool(pool).claimWithdraw(msg.sender);

        emit ClaimWithdraw(msg.sender, amount, pool2VaultId[pool], pool);
    }

    function claimWithdraw(address[] calldata pools) external {
        uint256 numOfPools = pools.length;
        for (uint256 i = 0; i < numOfPools; i++) {
            require(pool2VaultId[pools[i]] != 0, "Pool does not exist");

            uint256 amount = IORAStakePool(pools[i]).claimWithdraw(msg.sender);
            emit ClaimWithdraw(msg.sender, amount, pool2VaultId[pools[i]], pools[i]);
        }
    }

    function getVaultCurrentTVL(uint256 vaultId) public view returns (uint256) {
        uint256 totalTVL = 0;
        uint256 numOfPools = vaults[vaultId].pools.length;
        for (uint256 i = 0; i < numOfPools; i++) {
            address pool = vaults[vaultId].pools[i];
            totalTVL += IORAStakePool(pool).totalAssets();
        }
        return totalTVL;
    }

    function _validateStake(address pool, uint256 amount) internal view {
        require(amount > 0, "invalid staking amount.");
        PoolVault storage targetVault = vaults[pool2VaultId[pool]];
        if (getVaultCurrentTVL(pool2VaultId[pool]) + amount > targetVault.maxTVL) {
            revert ExceedingTVL();
        }
    }

    // **************** Read Functions ******************
    function withdrawStatus(address pool) external view returns (uint256 claimableAmount, uint256 pendingAmount) {
        (claimableAmount, pendingAmount) = IORAStakePool(pool).withdrawStatus(msg.sender);
    }

    function getVaultMaxTVL(uint256 vaultID) external view returns (uint256) {
        return vaults[vaultID].maxTVL;
    }

    function getPoolTVL(address pool) external view returns (uint256) {
        return IORAStakePool(pool).totalAssets();
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
        uint256 numOfPools = currVault.pools.length;
        for (uint256 i = 0; i < numOfPools; i++) {
            stakeAmount += getUserStakeAmountInPool(user, currVault.pools[i]);
        }
    }

    function getUserStakeAmountInPool(address user, address pool) public view returns (uint256 stakeAmount) {
        stakeAmount = IORAStakePool(pool).balanceOfAsset(user);
    }

    // **************** Admin Functions *****************
    function addVault(address[] calldata pools, uint256 maxTVL) external onlyOwner {
        PoolVault memory newVault = PoolVault(pools, maxTVL);
        vaults.push(newVault);
        uint256 numOfPools = pools.length;
        for (uint256 i = 0; i < numOfPools; i++) {
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
        uint256 vaultId = pool2VaultId[pool];

        address[] storage vaultPools = vaults[vaultId].pools;
        uint256 numOfPool = vaultPools.length;
        for (uint256 i = 0; i < numOfPool; i++) {
            if (vaultPools[i] == pool) {
                vaultPools[i] = vaultPools[vaultPools.length - 1];
                vaultPools.pop();
                break;
            }
        }

        delete pool2VaultId[pool];
    }

    function setPauseWithdraw(bool pauseWithdrawRq) external onlyOwner {
        _setPauseWithdraw(pauseWithdrawRq);
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

    function _setPauseWithdraw(bool pauseWithdrawRq) internal {
        pauseWithdraw = pauseWithdrawRq;
    }
}
