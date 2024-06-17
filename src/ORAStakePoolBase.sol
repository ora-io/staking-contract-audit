// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IORAStakePool} from "./interfaces/IORAStakePool.sol";
import {IORAStakeRouter} from "./interfaces/IORAStakeRouter.sol";

contract ORAStakePoolBase is OwnableUpgradeable, PausableUpgradeable, IORAStakePool, ERC20Upgradeable {
    using Math for uint256;

    address public stakingPoolRouter;
    address public permit2Address;
    address public stakingTokenAddress;

    mapping(address => mapping(uint256 => WithdrawRequest)) withdrawQueue;
    mapping(address => uint256) nextRequestID;
    mapping (address => uint256) nextUnclaimedID;

    uint256 public totalValueLocked;

    modifier onlyRouter() {
        require(msg.sender == stakingPoolRouter, "Have to invoke from router");
        _;
    }

    modifier tokenAddressIsValid(address tokenAddress) {
        require(tokenAddress != address(0), "invalid token address");
        _;
    }

    // **************** Setup Functions  ****************
    constructor() {
        _disableInitializers();
    }

    function initialize(address _router, address _owner) external initializer {
        __Ownable_init(_owner);
        __Pausable_init();
        __ERC20_init("ORA Stake Shares", "OSS"); //TODO: update here

        _pause();

        _setRouter(_router);
    }

    function transfer(address, uint256) public pure virtual override returns (bool) {
        revert();
    }

    function transferFrom(address, address, uint256) public pure virtual override returns (bool) {
        revert();
    }

    // **************** Write Functions  ****************
    function stake(address user, uint256 stakeAmount) external payable virtual onlyRouter whenNotPaused {
        _deposit(user, stakeAmount);
    }
    
    function requestWithdraw(address user, uint256 amount) external onlyRouter returns (uint256) {
        require(amount <= balanceOf(user), "invalid amount");
        withdrawQueue[user][nextRequestID[user]] = WithdrawRequest(amount, block.timestamp);
        nextRequestID[user] = nextRequestID[user] + 1;

        return nextRequestID[user] - 1;
    }

    function claimWithdraw(address user) external onlyRouter returns (uint256) {
        require(nextRequestID[user] != 0, "No withdraw request found.");
        require(nextRequestID[user] != nextUnclaimedID[user], "No new withdraw request.");

        uint256 claimableAmount = _updateAndCalculateClaimable(user);
        _withdraw(user, claimableAmount);

        return claimableAmount;
    }

    // ********* Write Internal Functions  ************
    function _deposit(address user, uint256 stakeAmount) internal virtual {
        _tokenTransferIn(user, stakeAmount);
        _mintETHStaking(user, stakeAmount);
    }

    function _tokenTransferIn(address, uint256 amount) internal virtual {
        require(msg.value == amount, "mismatched staking amount");
    }

    function _withdraw(address user, uint256 amount) internal virtual {
        require(amount <= balanceOf(user), "invalid withdraw request");

        if (amount > 0) {
            _burnETHStaking(user, amount);
            _tokenTransferOut(user, amount);
        }
    }

    function _tokenTransferOut(address user, uint256 amount) internal virtual {
        payable(user).transfer(amount);
    }

    function _mintETHStaking(address user, uint256 amount) internal {
        _mint(user, amount);
        totalValueLocked += amount;
    }

    function _burnETHStaking(address user, uint256 amount) internal {
        _burn(user, amount);
        totalValueLocked -= amount;
    }

    function _updateAndCalculateClaimable(address user) internal returns (uint256) {
        uint256 claimableAmount = 0;
        for (uint256 i = nextUnclaimedID[user]; i < nextRequestID[user]; i++) {
            WithdrawRequest storage request = withdrawQueue[user][i];
            if (block.timestamp > request.requestTimeStamp + IORAStakeRouter(stakingPoolRouter).withdrawGracePeriod()) {
                claimableAmount += request.amount;
                nextUnclaimedID[user] = i + 1;
            } else {
                break;
            }
        }

        return claimableAmount;
    }

    // **************** Read Functions ******************
    function withdrawStatus(address user) external view returns (uint256 claimableAmount, uint256 pendingAmount) {
        for (uint256 i = nextUnclaimedID[user]; i < nextRequestID[user]; i++) {
            WithdrawRequest storage request = withdrawQueue[user][i];
            if (block.timestamp < request.requestTimeStamp + IORAStakeRouter(stakingPoolRouter).withdrawGracePeriod()) {
                pendingAmount += request.amount;
            } else {
                claimableAmount += request.amount;
            }
        }
    }

    function currentTVL() external view returns (uint256) {
        return totalValueLocked;
    }

    function getWithdrawQueue(address user) external view returns (WithdrawRequest[] memory queue) {
        uint256 requestCount = nextRequestID[user];
        queue = new WithdrawRequest[](requestCount);

        for (uint256 i = 0; i < requestCount; i++) {
            queue[i] = withdrawQueue[user][i];
        }

        return queue;
    }

    // **************** Admin Functions *****************
    function setStakingPoolRouter(address router) external onlyOwner {
        _setRouter(router);
    }

    function setPermit2Address(address _permit2Address) external onlyOwner {
        permit2Address = _permit2Address;
    }

    function setStakingTokenAddress(address _tokenAddress) external onlyOwner tokenAddressIsValid(_tokenAddress) {
        stakingTokenAddress = _tokenAddress;
    }

    function _setRouter(address _router) internal {
        stakingPoolRouter = _router;
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
