// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockDeFi
 * @notice Simulates a DeFi protocol (like Uniswap/Aave)
 */
contract MockDeFi {
    IERC20 public immutable token;

    // User deposits
    mapping(address => uint256) public deposits;

    // Total value locked
    uint256 public totalValueLocked;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Swapped(address indexed user, uint256 amountIn, uint256 amountOut);

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
     * @notice Deposit tokens to earn yield
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");

        // Transfer tokens from user
        token.transferFrom(msg.sender, address(this), amount);

        // Track deposit
        deposits[msg.sender] += amount;
        totalValueLocked += amount;

        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Withdraw deposited tokens
     */
    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient balance");

        // Update state
        deposits[msg.sender] -= amount;
        totalValueLocked -= amount;

        // Transfer tokens back
        token.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Simulate token swap (1:1 for simplicity)
     */
    function swap(uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be > 0");

        // Take input tokens
        token.transferFrom(msg.sender, address(this), amountIn);

        // Simple 1:1 swap (minus 1% fee)
        amountOut = (amountIn * 99) / 100;

        // Give output tokens
        token.transfer(msg.sender, amountOut);

        emit Swapped(msg.sender, amountIn, amountOut);
    }

    /**
     * @notice Get user's balance
     */
    function balanceOf(address user) external view returns (uint256) {
        return deposits[user];
    }
}
