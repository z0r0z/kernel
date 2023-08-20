// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing necessary interfaces
import "account-abstraction/interfaces/IEntryPoint.sol";
import "src/interfaces/IValidator.sol";
import "src/interfaces/IKernel.sol";
import "src/common/Constants.sol";
import "src/common/Structs.sol";

/// @title Kernel Storage Contract
/// @author taek<leekt216@gmail.com>
/// @notice This contract serves as the storage module for the Kernel contract.
/// @dev This contract should only be used by the main Kernel contract.
abstract contract KernelStorage is IKernel {
    IEntryPoint public immutable entryPoint; // The entry point of the contract

    // Modifier to check if the function is called by the entry point, the contract itself or the owner
    modifier onlyFromEntryPointOrSelf() {
        if (msg.sender != address(entryPoint) && msg.sender != address(this)) {
            revert NotAuthorizedCaller();
        }
        _;
    }

    /// @param _entryPoint The address of the EntryPoint contract
    /// @dev Sets up the EntryPoint contract address
    constructor(IEntryPoint _entryPoint) {
        entryPoint = _entryPoint;
        getKernelStorage().defaultValidator = IKernelValidator(address(1));
    }

    // Function to initialize the wallet kernel
    function initialize(IKernelValidator _defaultValidator, bytes calldata _data) external override payable {
        _setInitialData(_defaultValidator, _data);
    }

    // Function to upgrade the contract to a new implementation
    function upgradeTo(address _newImplementation) external override payable onlyFromEntryPointOrSelf {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _newImplementation)
        }
        emit Upgraded(_newImplementation);
    }

    // Function to get the wallet kernel storage
    function getKernelStorage() internal pure returns (WalletKernelStorage storage ws) {
        assembly {
            ws.slot := KERNEL_STORAGE_SLOT
        }
    }

    // Functions to get the nonce from the entry point
    function getNonce() public view virtual returns (uint256) {
        return entryPoint.getNonce(address(this), 0);
    }

    function getNonce(uint192 key) public view virtual returns (uint256) {
        return entryPoint.getNonce(address(this), key);
    }

    // query storage
    function getDefaultValidator() public view returns (IKernelValidator validator) {
        assembly {
            validator := shr(80, sload(KERNEL_STORAGE_SLOT_1))
        }
    }

    function getDisabledMode() public view returns (bytes4 disabled) {
        assembly {
            disabled := shl(224, sload(KERNEL_STORAGE_SLOT_1))
        }
    }

    function getLastDisabledTime() public view returns (uint48) {
        return getKernelStorage().lastDisabledTime;
    }

    /// @notice Returns the execution details for a specific function signature
    /// @dev This function can be used to get execution details for a specific function signature
    /// @param _selector The function signature
    /// @return ExecutionDetail struct containing the execution details
    function getExecution(bytes4 _selector) public view returns (ExecutionDetail memory) {
        return getKernelStorage().execution[_selector];
    }

    /// @notice Changes the execution details for a specific function selector
    /// @dev This function can only be called from the EntryPoint contract, the contract owner, or itself
    /// @param _selector The selector of the function for which execution details are being set
    /// @param _executor The executor to be associated with the function selector
    /// @param _validator The validator contract that will be responsible for validating operations associated with this function selector
    /// @param _validUntil The timestamp until which the execution details are valid
    /// @param _validAfter The timestamp after which the execution details are valid
    function setExecution(
        bytes4 _selector,
        address _executor,
        IKernelValidator _validator,
        ValidUntil _validUntil,
        ValidAfter _validAfter,
        bytes calldata _enableData
    ) external payable override onlyFromEntryPointOrSelf {
        getKernelStorage().execution[_selector] = ExecutionDetail({
            executor: _executor,
            validator: _validator,
            validUntil: _validUntil,
            validAfter: _validAfter
        });
        _validator.enable(_enableData);
        emit ExecutionChanged(_selector, _executor, address(_validator));
    }

    function setDefaultValidator(IKernelValidator _defaultValidator, bytes calldata _data)
        external
        payable
        override
        onlyFromEntryPointOrSelf
    {
        IKernelValidator oldValidator = getKernelStorage().defaultValidator;
        getKernelStorage().defaultValidator = _defaultValidator;
        emit DefaultValidatorChanged(address(oldValidator), address(_defaultValidator));
        _defaultValidator.enable(_data);
    }

    /// @notice Updates the disabled mode
    /// @dev This function can be used to update the disabled mode
    /// @param _disableFlag The new disabled mode
    function disableMode(bytes4 _disableFlag) external payable onlyFromEntryPointOrSelf {
        getKernelStorage().disabledMode = _disableFlag;
        getKernelStorage().lastDisabledTime = uint48(block.timestamp);
    }

    function _setInitialData(IKernelValidator _defaultValidator, bytes calldata _data) internal virtual {
        address validator;
        assembly {
            validator := shr(80, sload(KERNEL_STORAGE_SLOT_1))
        }
        if (address(validator) != address(0)) {
            revert AlreadyInitialized();
        }
        getKernelStorage().defaultValidator = _defaultValidator;
        _defaultValidator.enable(_data);
    }
}
