// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IEntryPoint.sol";
import "../interfaces/IAccount.sol";
import "../interfaces/IPaymaster.sol";

/**
 * @title SimpleEntryPoint
 * @notice Simplified EntryPoint for demo purposes
 */
contract SimpleEntryPoint is IEntryPoint {
    // Storage
    mapping(address => uint256) public deposits;

    // Events
    event UserOperationEvent(
        bytes32 indexed userOpHash,
        address indexed sender,
        address indexed paymaster,
        uint256 nonce,
        bool success,
        uint256 actualGasCost
    );

    event Deposited(address indexed account, uint256 totalDeposit);

    // Errors
    error ValidationFailed();
    error ExecutionFailed();
    error InsufficientDeposit();

    /**
     * @notice Main function to handle user operations
     */
    function handleOps(
        UserOperation[] calldata ops,
        address payable beneficiary
    ) external override {
        uint256 opsLength = ops.length;

        for (uint256 i = 0; i < opsLength; i++) {
            UserOperation calldata userOp = ops[i];
            _handleOp(userOp, beneficiary);
        }
    }

    /**
     * @notice Process single user operation
     */
    function _handleOp(
        UserOperation calldata userOp,
        address payable beneficiary
    ) internal {
        uint256 preGas = gasleft();
        bytes32 userOpHash = getUserOpHash(userOp);

        // Phase 1: VALIDATION
        uint256 validationData = _validateUserOp(userOp, userOpHash);

        if (validationData != 0) {
            revert ValidationFailed();
        }

        // Phase 2: EXECUTION
        bool success = _executeUserOp(userOp);

        // Phase 3: GAS ACCOUNTING
        uint256 actualGas = preGas - gasleft();
        uint256 actualGasCost = actualGas * tx.gasprice;

        _compensateBundler(userOp, actualGasCost, beneficiary);

        emit UserOperationEvent(
            userOpHash,
            userOp.sender,
            _getPaymasterAddress(userOp),
            userOp.nonce,
            success,
            actualGasCost
        );
    }

    /**
     * @notice Validate user operation
     */
    function _validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal returns (uint256 validationData) {
        // Calculate required prefund
        uint256 requiredPrefund = userOp.callGasLimit * userOp.maxFeePerGas;

        // Check if paymaster will sponsor
        if (userOp.paymasterAndData.length >= 20) {
            address paymaster = _getPaymasterAddress(userOp);

            // Validate with paymaster
            try
                IPaymaster(paymaster).validatePaymasterUserOp(
                    userOp,
                    userOpHash,
                    requiredPrefund
                )
            returns (bytes memory context, uint256 _validationData) {
                validationData = _validationData;
            } catch {
                return 1; // Validation failed
            }
        } else {
            // Account pays itself
            if (deposits[userOp.sender] < requiredPrefund) {
                revert InsufficientDeposit();
            }
        }

        // Validate with account
        try
            IAccount(userOp.sender).validateUserOp(
                userOp,
                userOpHash,
                requiredPrefund
            )
        returns (uint256 _validationData) {
            if (_validationData != 0) {
                validationData = _validationData;
            }
        } catch {
            return 1; // Validation failed
        }

        return validationData;
    }

    /**
     * @notice Execute user operation
     */
    function _executeUserOp(
        UserOperation calldata userOp
    ) internal returns (bool success) {
        (success, ) = userOp.sender.call{gas: userOp.callGasLimit}(
            userOp.callData
        );

        return success;
    }

    /**
     * @notice Compensate bundler for gas
     */
    function _compensateBundler(
        UserOperation calldata userOp,
        uint256 actualGasCost,
        address payable beneficiary
    ) internal {
        address paymaster = _getPaymasterAddress(userOp);

        if (paymaster != address(0)) {
            // Paymaster pays
            deposits[paymaster] -= actualGasCost;
        } else {
            // Account pays
            deposits[userOp.sender] -= actualGasCost;
        }

        // Transfer to bundler
        beneficiary.transfer(actualGasCost);
    }

    /**
     * @notice Get paymaster address from userOp
     */
    function _getPaymasterAddress(
        UserOperation calldata userOp
    ) internal pure returns (address) {
        if (userOp.paymasterAndData.length < 20) {
            return address(0);
        }

        return address(bytes20(userOp.paymasterAndData[0:20]));
    }

    /**
     * @notice Calculate hash of user operation
     */
    function getUserOpHash(
        UserOperation calldata userOp
    ) public view override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    userOp.sender,
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.callGasLimit,
                    userOp.verificationGasLimit,
                    userOp.preVerificationGas,
                    userOp.maxFeePerGas,
                    userOp.maxPriorityFeePerGas,
                    keccak256(userOp.paymasterAndData),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @notice Deposit funds for gas payments
     */
    function depositTo(address account) external payable override {
        deposits[account] += msg.value;
        emit Deposited(account, deposits[account]);
    }

    /**
     * @notice Get deposit balance
     */
    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return deposits[account];
    }

    // Receive ETH
    receive() external payable {
        deposits[msg.sender] += msg.value;
    }
}
