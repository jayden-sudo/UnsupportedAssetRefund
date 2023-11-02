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
