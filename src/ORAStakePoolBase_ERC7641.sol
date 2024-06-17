// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC7641Upgradeable} from "./utils/ERC7641Upgradeable.sol";
import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";

import {IORAStakePool} from "./interfaces/IORAStakePool.sol";
import {IORAStakeRouter} from "./interfaces/IORAStakeRouter.sol";

contract ORAStakePoolBase_ERC7641 is ORAStakePoolBase, ERC7641Upgradeable {
    function initialize(
        address _router,
        address _initialOwner,
        string memory name,
        uint256 supply,
        uint256 _percentClaimable,
        uint256 _snapshotInterval
    ) external initializer {
        __Ownable_init(_initialOwner);
        __Pausable_init();
        __ERC7641_init(name, supply, _percentClaimable, _snapshotInterval);

        _pause();

        _setRouter(_router);
    }

    function _update(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20Upgradeable, ERC7641Upgradeable)
    {
        ERC7641Upgradeable._update(from, to, amount);
    }

    function transfer(address, uint256) public pure override(ORAStakePoolBase, ERC7641Upgradeable) returns (bool) {
        revert();
    }

    function transferFrom(address, address, uint256)
        public
        pure
        override(ORAStakePoolBase, ERC7641Upgradeable)
        returns (bool)
    {
        revert();
    }
}
