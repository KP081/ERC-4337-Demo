// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./UserOperation.sol";

interface IEntryPoint {
    function handleOps(
        UserOperation[] calldata ops,
        address payable beneficiary
    ) external;

    function getUserOpHash(
        UserOperation calldata userOp
    ) external view returns (bytes32);

    function depositTo(address account) external payable;

    function balanceOf(address account) external view returns (uint256);
}