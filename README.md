# ORA Staking Contracts

ORA Staking Pools allows user to stake in with multiple Tokens and remain the original yield.

## Pool List

ETH Vault:
- ETH
- STONE
- stETH

OLM Vault:
- OLM (OpenLM RevShare Token)

## Token Types

**Native ETH**
- only the ETH pool deals with native ETH

**ERC20Permit**
- for tokens that support ERC20Permit (e.g. OLM & stETH), the corresponding pools should support this feature to improve UX

**Non-ERC20Permit**
- for tokens that doesn't support ERC20Permit (e.g. STONE), the corresponding pools should support both Uniswap Permit2 & the original ERC20 allowance schema

**ERC7641**
- for ERC7641 tokens (e.g. OLM), the corresponding pools should be able to inherit the revshare schema and allow stakeholders to claim their part of revenue.

## Architecture

**Router Contract**
- serves as the main entrance for users & frontend interface
- serves as the single source of truth for latest running vaults & pools
- each ***vault*** has a shared *target TVL* among its *pools*, the staking process of each vault will be paused after reaching the *target TVL*, until someone withdraw.

**Pool Contract**
- ***pool*** holds the actual stake token for the token it represents, to deal with the variety of different token schema
- only the *Router contract* can call the write functions of the *Pool contract*

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
