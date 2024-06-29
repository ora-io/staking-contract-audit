// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IORAStakePool} from "./interfaces/IORAStakePool.sol";
import {IORAStakeRouter} from "./interfaces/IORAStakeRouter.sol";

contract ORAStakePoolBase is OwnableUpgradeable, PausableUpgradeable, IORAStakePool, ERC20Upgradeable {
    using Math for uint256;

    address public stakingPoolRouter;
    address public permit2Address;
    address public stakingTokenAddress;

    bool public pauseWithdraw;

    mapping(address => mapping(uint256 => WithdrawRequest)) withdrawQueue;
    mapping(address => uint256) nextRequestID;
    mapping(address => uint256) public nextUnclaimedID; // visible for getting claim status

    modifier onlyRouter() {
        require(msg.sender == stakingPoolRouter, "Have to invoke from router");
        _;
    }

    modifier whenNotPausedWithdraw() {
        require(pauseWithdraw == false, "withdraw is paused.");
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
        _setPauseWithdraw(true);
    }

    // **************** Write Functions  ****************
    function stake(address user, uint256 stakeAmount) external payable virtual onlyRouter whenNotPaused {
        _deposit(user, stakeAmount);
    }

    function requestWithdraw(address user, uint256 amount)
        external
        onlyRouter
        whenNotPausedWithdraw
        returns (uint256)
    {
        uint256 totalRequestedAmount = 0;
        for (uint256 i = nextUnclaimedID[user]; i < nextRequestID[user]; i++) {
            totalRequestedAmount += withdrawQueue[user][i].amount;
        }

        require(totalRequestedAmount + amount <= _convertToAssets(balanceOf(user)), "invalid amount");

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
    function _deposit(address user, uint256 amount) internal virtual {
        uint256 shares = amount;
        uint256 existingAsset = totalAssets();
        if (existingAsset != 0 && totalSupply() != 0) {
            shares = _convertToShares(amount);
        }

        _mint(user, shares);
        _tokenTransferIn(user, amount);
    }

    function _withdraw(address user, uint256 amount) internal virtual {
        uint256 shares = _convertToShares(amount);
        require(shares <= balanceOf(user), "invalid withdraw request");

        if (amount > 0) {
            _burn(user, shares);
            _tokenTransferOut(user, amount);
        }
    }

    function _tokenTransferIn(address user, uint256 amount) internal virtual {
        require(msg.value == 0, "eth amount should be 0.");

        IERC20(stakingTokenAddress).transferFrom(user, address(this), amount);
    }

    function _tokenTransferOut(address user, uint256 amount) internal virtual {
        IERC20(stakingTokenAddress).transfer(user, amount);
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

    function _setRouter(address _router) internal {
        stakingPoolRouter = _router;
    }

    function _setPauseWithdraw(bool pauseWithdrawRq) internal {
        pauseWithdraw = pauseWithdrawRq;
    }

    // **************** Read Functions ******************
    function withdrawStatus(address user) external view returns (uint256 claimableAmount, uint256 pendingAmount) {
        return _withdrawStatusAssets(user);
    }

    function _withdrawStatusAssets(address user)
        internal
        view
        returns (uint256 claimableAmount, uint256 pendingAmount)
    {
        for (uint256 i = nextUnclaimedID[user]; i < nextRequestID[user]; i++) {
            WithdrawRequest storage request = withdrawQueue[user][i];
            if (block.timestamp < request.requestTimeStamp + IORAStakeRouter(stakingPoolRouter).withdrawGracePeriod()) {
                pendingAmount += request.amount;
            } else {
                claimableAmount += request.amount;
            }
        }
    }

    function getWithdrawQueue(address user) external view returns (WithdrawRequest[] memory queue) {
        uint256 requestCount = nextRequestID[user];
        queue = new WithdrawRequest[](requestCount);

        for (uint256 i = 0; i < requestCount; i++) {
            queue[i] = withdrawQueue[user][i];
        }

        return queue;
    }

    function balanceOfAsset(address user) external view virtual returns (uint256) {
        return _convertToAssets(balanceOf(user));
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets);
    }

    function totalAssets() public view virtual returns (uint256) {
        return stakingTokenAddress == address(0)
            ? address(this).balance
            : IERC20(stakingTokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets) internal view returns (uint256) {
        return assets.mulDiv(totalSupply(), totalAssets(), Math.Rounding.Floor);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares) internal view returns (uint256) {
        return shares.mulDiv(totalAssets(), totalSupply(), Math.Rounding.Floor);
    }

    // **************** Admin Functions *****************
    function setStakingPoolRouter(address router) external onlyOwner {
        _setRouter(router);
    }

    function setPauseWithdraw(bool pauseWithdrawRq) external onlyOwner {
        _setPauseWithdraw(pauseWithdrawRq);
    }

    function setPermit2Address(address _permit2Address) external onlyOwner {
        permit2Address = _permit2Address;
    }

    function setStakingTokenAddress(address _tokenAddress) external onlyOwner tokenAddressIsValid(_tokenAddress) {
        stakingTokenAddress = _tokenAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
