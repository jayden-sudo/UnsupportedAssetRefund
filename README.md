# Unsupported Asset Retrieval Protocol

## Overview

The Unsupported Asset Retrieval Protocol is designed to recover ERC20 tokens mistakenly sent to a smart contract without the required deposit function call. This protocol leverages AxiomRepl to enable users to reclaim their assets securely without compromising the integrity of the smart contract.

## Background

Smart contracts typically require users to interact through specific functions to deposit assets. Direct transfers not using these functions can result in the permanent loss of assets. AxiomRepl provides a solution to recover such assets.

### Example Scenario

Consider a smart contract that accepts ERC20 tokens:

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

If a user sends tokens directly to the contract's address, bypassing the `deposit()` function, those tokens would be stuck. AxiomRepl allows users to prove the occurrence of such a transfer and retrieve their tokens.

## Protocol Mechanics

For the retrieval of supported tokens, the process involves staking, a challenge period, and the possibility of zero-knowledge proofs to ensure honesty and security. This complex scenario is beyond the scope of the current demonstration.

## Repository Structure

- **AxiomRepl:** [View on AxiomRepl](https://repl.axiom.xyz/?gist=966aacec3eff95abae5c31a6d5f705ce)
- **Smart Contract Code:** [View on GitHub](https://github.com/jayden-sudo/UnsupportedAssetRefund/tree/main/src)
- **Example Transaction:** [View on Goerli Etherscan](https://goerli.etherscan.io/tx/0x904bd694c92330f43490914c2ebef26b25fdf117dc93399e2658a72dc5b88d7f#eventlog)

## Demonstration Guide

### Prerequisites

Ensure you have [Node.js](https://nodejs.org/) and [Yarn](https://yarnpkg.com/) installed.

### Steps

#### 1. Transfer Unsupported ERC20 Token

Simulate an unsupported deposit to the protocol:

- ERC20 Token Address: [0xbaE940De6ef7D897Ad76bA8bfa7f93939F82E976](https://goerli.etherscan.io/address/0xbaE940De6ef7D897Ad76bA8bfa7f93939F82E976#readContract)
- Protocol Address: [0x430faeE7cF005d848dE5BD4F6c385D552430aE04](https://goerli.etherscan.io/address/0x430faeE7cF005d848dE5BD4F6c385D552430aE04#code)
- Example TX: [0x674a5882e6191482b80c625a805736c7ec6c85d0b909a7ba8308c8a5449c838a](https://goerli.etherscan.io/tx/0x674a5882e6191482b80c625a805736c7ec6c85d0b909a7ba8308c8a5449c838a)
- ![Transfer Step 1](imgs/1.png)
- ![Transfer Step 2](imgs/2.png)

#### 2. Submit zk Proof

Prove the unsupported transfer to initiate the refund:

1. Start the web server:

   ```sh
   yarn dev
   ```

2. Visit `localhost:3000` and input the transaction details.
3. Click "Build and Send Query (on Goerli)".
4. Proof TX: [0xa4d7df3613d761c36efad9c685d5ca565a25366a1748e48bf3e3ef3e9864dd1b](https://goerli.etherscan.io/tx/0xa4d7df3613d761c36efad9c685d5ca565a25366a1748e48bf3e3ef3e9864dd1b)

- ![zk Proof Submission](imgs/3.png)

#### 3. AxiomRepl Callback

AxiomRepl will confirm the proof and initiate a callback:

- Axiom Explorer Query: [View Query](https://explorer.axiom.xyz/v2/goerli/mock/query/37936641960384140553271310167170655117928683811062763716838577295416631454366)
- Etherscan TX: [0xd3ab31ddad9991c7bf37b8f0546a81675903757ab8a5217eea3a12a03e2d9f7c](https://goerli.etherscan.io/tx/0xd3ab31ddad9991c7bf37b8f0546a81675903757ab8a5217eea3a12a03e2d9f7c#eventlog)
- ![AxiomRepl Callback Step 1](imgs/4.png)
- ![AxiomRepl Callback Step 2](imgs/5.png)

#### 4. Initiate UnsupportedTokenWithdrawal

Users can now withdraw their unsupported tokens:

- Withdrawal TX: [0x904bd694c92330f43490914c2ebef26b25fdf117dc93399e2658a72dc5b88d7f](https://goerli.etherscan.io/tx/0x904bd694c92330f43490914c2ebef26b25fdf117dc93399e2658a72dc5b88d7f)
- ![Withdrawal Step 1](imgs/6.png)
- ![Withdrawal Step 2](imgs/7.png)

## Conclusion

This protocol provides a secure method for users to reclaim ERC20 tokens sent in error. The demonstration above guides you through the process to safely retrieve your assets.
