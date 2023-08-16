// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import "src/factory/AdminLessERC1967Factory.sol";
import "src/factory/MultiECDSAFactory.sol";
import "src/Kernel.sol";
import "src/validator/MultiECDSAValidator.sol";
// test artifacts
// test utils
import "forge-std/Test.sol";
import {ERC4337Utils, KernelTestBase} from "./utils/ERC4337Utils.sol";

using ERC4337Utils for EntryPoint;
contract KernelMultiOwnedTest is KernelTestBase {
    address secondOwner;
    uint256 secondOwnerKey;
    function setUp() public {
        _initialize();
        MultiECDSAFactory newFactory = new MultiECDSAFactory(factoryOwner, entryPoint);
        vm.startPrank(factoryOwner);
        newFactory.setImplementation(address(kernelImpl), true);
        defaultValidator = new MultiECDSAValidator();
        (secondOwner, secondOwnerKey) = makeAddrAndKey("secondOwner");
        address[] memory owners = new address[](2);
        owners[0] = owner;
        owners[1] = secondOwner;
        newFactory.setOwners(owners);
        vm.stopPrank();
        factory = KernelFactory(address(newFactory));
        _setAddress();
    }

    function getInitializeData() internal override view returns(bytes memory) {
        return abi.encodeWithSelector(
            KernelStorage.initialize.selector,
            defaultValidator,
            abi.encodePacked(factory)
        );
    }

    function signUserOp(UserOperation memory op) internal override view returns(bytes memory) {
        return abi.encodePacked(bytes4(0x00000000), entryPoint.signUserOpHash(vm, ownerKey, op));
    }

    function signHash(bytes32 hash) internal override view returns(bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(hash,kernel))));
        return abi.encodePacked(r, s, v);
    }
}
