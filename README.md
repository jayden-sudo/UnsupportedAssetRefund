# Unsupported Asset Retrieval

## Background

Typically, a smart contract protocol receives user assets through specific functions and predefined processes. If a user fails to adhere to these predefined processes, any assets they transfer into the protocol become irretrievable.

Thankfully, with the introduction of AxiomRepl, users can retrieve their lost assets without compromising the security of the protocol.

Consider a simple example: a smart contract designed to accept specific ERC20 deposits from users.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SomeProtocol {
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    mapping(address => uint256) public balances;
    IERC20 public immutable allowedToken;

    constructor(IERC20 _allowedToken) {
        allowedToken = _allowedToken;
    }

    function deposit(uint256 amount) external {
        allowedToken.safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdrawal(uint256 amount) external {
        require(balances[msg.sender] >= amount, "insufficient balance");
        balances[msg.sender] -= amount;
        allowedToken.safeTransfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }
}
```

In this scenario, users face a risk: depositing assets in ways other than calling the `deposit()` function makes the assets irretrievable. For instance, if a user directly transfers ERC20 tokens to the `SomeProtocol` contract, those tokens become locked and inaccessible.

To address this challenge, we introduce AxiomRepl. By proving to `SomeProtocol` that a user has made an unsupported token transfer, AxiomRepl allows the user to retrieve the corresponding assets.

For supported tokens (like `allowedToken`), if users accidentally deposit assets outside the `deposit()` function, the retrieval process might be more intricate. A possible scenario involves User A staking tokens as collateral for a retrieval claim, with a 1-day challenge window. If, within this period, User B (or any user) can provide a zero-knowledge proof (zk-proof) that User A's deposit transaction contains the `event Deposit(address indexed user, uint256 amount)`, it implies User A acted dishonestly. As a result, User B receives all of User A's collateral. Given the complexity of this scenario, we don't plan to include it in the current demo.

## Code Structure

- **AxiomRepl:** [Link to AxiomRepl](https://repl.axiom.xyz/?gist=966aacec3eff95abae5c31a6d5f705ce)
  
- **Smart Contract:** [ProofOfTokenTransfer on GitHub](https://github.com/jayden-sudo/UnsupportedAssetRefund/blob/main/src/ProofOfTokenTransfer.sol)
  
- **Test Transaction:** [Transaction on Goerli Etherscan](https://goerli.etherscan.io/tx/0x7fe7c993a0720c78414942c9ee8fc062bfaa0419064f0c3d691699843f8d3ade#eventlog)

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

<https://book.getfoundry.sh/>

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil

```shell
anvil
```

### Deploy

```shell
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
cast --help
```
