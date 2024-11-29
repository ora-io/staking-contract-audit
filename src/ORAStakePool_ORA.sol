// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC7641} from "./interfaces/IERC7641.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IORAStakePoolPermit} from "./interfaces/IORAStakePoolPermit.sol";
import {ORAStakePoolPermit} from "./ORAStakePoolPermit.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ORAStakePool_ORA is ORAStakePoolPermit {
    using Math for uint256;

    address WETH;
    address router;

    function migrateAsset(address user, uint256 assetAmount, address migrationAddress)
        public
        override
        onlyRouter
        whenNotPausedWithdraw
    {
        require(migrationAddress != address(0), "invalid migration address.");

        uint256 shares = _convertToShares(assetAmount, Math.Rounding.Ceil, 0, false);
        _burn(user, shares);
        _tokenTransferOut(migrationAddress, assetAmount);
    }

    function processAsset(address user, uint256 assetAmount) public override onlyRouter whenNotPaused {
        uint256 shares = _convertToShares(assetAmount, Math.Rounding.Floor, assetAmount, true);
        require(shares > 0, "invalid deposit amount");
        _mint(user, shares);
    }

    function poolRevenueClaimAndConvert(uint256 snapshotId, uint256 amountoutMin) public {
        poolRevenueClaim(snapshotId);
        poolRevenueConvert(amountoutMin);
    }

    function poolRevenueClaim(uint256 snapshotId) public {
        IERC7641(stakingTokenAddress).claim(snapshotId);
    }

    function poolRevenueConvert(uint256 amountoutMin) public onlyOwner {
        uint256 amountIn = address(this).balance;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: stakingTokenAddress,
            fee: 3000,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: amountoutMin,
            sqrtPriceLimitX96: 0
        });

        ISwapRouter(router).exactInputSingle{value: amountIn}(params);
    }

    function setWETHAddress(address _WETH) external onlyOwner {
        WETH = _WETH;
    }

    function setSwapRouterAddress(address _router) external onlyOwner {
        router = _router;
    }

    // given a list of stakers, return a subset of stakers that have a balance greater than the threshold and 
    // the number of stakers
    // return length to avoid redundant loops, since memory arrays can't be resized
    function filterByThreshold(address[] memory stakers, uint256 threshold) public view returns (address[] memory, uint256 length) {
        address[] memory filtered = new address[](stakers.length);

        for (uint256 i = 0; i < stakers.length; i++) {
            if (this.balanceOfAsset(stakers[i]) >= threshold) {
                filtered[length] = stakers[i];
                length++;
            }
        }

        return (filtered, length);
    }

    receive() external payable {}
}
