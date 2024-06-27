// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract MyToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory tokenName, string memory symbol, address initialOwner) public initializer {
        __ERC20_init(tokenName, symbol);
        __Ownable_init(initialOwner);
        __ERC20Permit_init(tokenName);
        __UUPSUpgradeable_init();

        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // mock function just return the balance
    function getSharesByPooledEth(uint256 _pooledEthAmount) external pure returns (uint256) {
        return _pooledEthAmount;
    }

    function getPooledEthByShares(uint256 _pooledEthShares) external pure returns (uint256) {
        return _pooledEthShares;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
