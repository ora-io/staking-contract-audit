// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ORAStakePoolPermit} from "./ORAStakePoolPermit.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IORAStakePoolPermit} from "./interfaces/IORAStakePoolPermit.sol";
import {IStETH} from "./interfaces/IStETH.sol";

contract ORAStakePool_StETH is ORAStakePoolPermit {}
