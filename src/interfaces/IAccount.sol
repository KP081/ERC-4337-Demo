// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./UserOperation.sol";

interface IAccount {
    
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uitn256 missingAccountFunds
    ) external returns(uint256 validationData); 

}