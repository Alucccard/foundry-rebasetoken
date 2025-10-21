# This is a Cross-chain Rebase Token project
## 1. Allows users to deposit into a vault and in return, receiver rebase tokens that represent their underlying balance.
## 2. Rebase token => balance of function is dynamic to show the changing balance with time.
    - Balance increases with time linearly.
    - mint tokens to our users every time when minting, burning, transferring, bridging.
## 3. Interest rate
    - Indivually set an interest rate for each user based on global interest rate.
    - The global interest rate can only decrease to incetivise/reward early adopters.
    - 


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
