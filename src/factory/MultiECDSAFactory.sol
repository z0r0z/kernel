pragma solidity ^0.8.0;

import "./KernelFactory.sol";
import "src/interfaces/IAddressBook.sol";

contract MultiECDSAFactory is KernelFactory, IAddressBook {
    address[] owners;
    constructor(address _owner, IEntryPoint _entryPoint) KernelFactory(_owner, _entryPoint) {}

    function getOwners() external override view returns (address[] memory) {
        return owners;
    }

    function setOwners(address[] memory _owners) external onlyOwner {
        owners = _owners;
    }
}
