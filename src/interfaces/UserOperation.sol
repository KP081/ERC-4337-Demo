// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct UserOperation {
    address sender;              // Smart account address
    uint256 nonce;              // Anti-replay protection
    bytes initCode;             // For wallet creation (if needed)
    bytes callData;             // Actual transaction data
    uint256 callGasLimit;       // Gas for execution
    uint256 verificationGasLimit; // Gas for validation
    uint256 preVerificationGas;  // Fixed gas overhead
    uint256 maxFeePerGas;       // Max gas price
    uint256 maxPriorityFeePerGas; // Priority fee
    bytes paymasterAndData;     // Paymaster address + data
    bytes signature;            // User's signature
}