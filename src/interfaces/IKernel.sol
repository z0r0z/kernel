// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Operation} from "src/common/Enum.sol";
import {ValidationData, ValidUntil, ValidAfter} from "src/common/Types.sol";
import {UserOperation} from "account-abstraction/core/EntryPoint.sol";
import {IKernelValidator} from "./IValidator.sol";

interface IKernel {
    // Event declarations
    event Upgraded(address indexed newImplementation);
    event DefaultValidatorChanged(address indexed oldValidator, address indexed newValidator);
    event ExecutionChanged(bytes4 indexed selector, address indexed executor, address indexed validator);

    // Error declarations
    error NotAuthorizedCaller();
    error AlreadyInitialized();

    // -- Kernel.sol --
    function execute(address _to, uint256 _value, bytes calldata _data, Operation operation) external payable;

    function validateUserOp(UserOperation memory _op, bytes32 _hash, uint256 _missingAccountFunds) external payable returns(ValidationData validationData);

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns(bytes4);

    // -- KernelStorage.sol --
    function initialize(IKernelValidator _kernelValidator, bytes calldata _data) external payable;

    function upgradeTo(address _newImplementation) external payable;

    function setExecution(bytes4 _selector, address _executor, IKernelValidator _validator, ValidUntil _validUntil, ValidAfter _validAfter, bytes calldata _enableData) external payable;

    function setDefaultValidator(IKernelValidator _validator, bytes calldata _data) external payable;

    function disableMode(bytes4 _disableFlag) external payable;
}
