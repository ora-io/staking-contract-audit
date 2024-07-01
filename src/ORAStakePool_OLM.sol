// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC7641} from "./interfaces/IERC7641.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IORAStakePoolPermit} from "./interfaces/IORAStakePoolPermit.sol";
import {ORAStakePoolPermit} from "./ORAStakePoolPermit.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";

contract ORAStakePool_OLM is ORAStakePoolPermit {
    address WETH;
    address router;

    function poolRevenueClaimAndConvert(uint256 snapshotId) public onlyOwner {
        poolRevenueClaim(snapshotId);
        poolRevenueConvert();
    }

    function poolRevenueClaim(uint256 snapshotId) public onlyOwner {
        IERC7641(stakingTokenAddress).claim(snapshotId);
    }

    function poolRevenueConvert() public onlyOwner {
        uint256 amountIn = address(this).balance;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: stakingTokenAddress,
            fee: 3000,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: 0,
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

    receive() external payable {}
}
