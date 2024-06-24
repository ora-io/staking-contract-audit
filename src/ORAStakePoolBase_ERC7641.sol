// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC7641Upgradeable} from "./utils/ERC7641Upgradeable.sol";
import {ORAStakePoolBase} from "./ORAStakePoolBase.sol";

import {IERC7641} from "./interfaces/IERC7641.sol";
import {IORAStakePool} from "./interfaces/IORAStakePool.sol";
import {IORAStakeRouter} from "./interfaces/IORAStakeRouter.sol";

contract ORAStakePoolBase_ERC7641 is ERC7641Upgradeable, ORAStakePoolBase {
    event RevenueClaimed(uint256 indexed snapshotId);

    function initialize(
        address _router,
        address _initialOwner,
        string memory name,
        string memory symbol,
        uint256 _snapshotInterval
    ) external initializer {
        __Ownable_init(_initialOwner);
        __Pausable_init();
        __ERC20_init(name, symbol);
        __ERC7641_init(name, 0, 100, _snapshotInterval);

        _pause();

        _setRouter(_router);
    }

    function claimRevenue(uint256 _snapshotId) external tokenAddressIsValid(stakingTokenAddress) {
        IERC7641(stakingTokenAddress).claim(_snapshotId);

        emit RevenueClaimed(_snapshotId);
    }

    function _update(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20Upgradeable, ERC7641Upgradeable)
    {
        ERC7641Upgradeable._update(from, to, amount);
    }

    function redeemableOnBurn(uint256) external pure override returns (uint256) {
        return 0;
    }

    function burn(uint256) external pure override {
        revert();
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
