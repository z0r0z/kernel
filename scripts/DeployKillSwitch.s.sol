pragma solidity ^0.8.0;

import "src/validator/KillSwitchValidator.sol";
import "src/executor/KillSwitchAction.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployKillSwitch is Script {
    address internal constant DETERMINISTIC_CREATE2_FACTORY = 0x7A0D94F55792C434d74a40883C6ed8545E406D12;
    function run() public {
        uint256 key = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(key);
        bytes memory bytecode;
        bool success;
        bytes memory returnData;
        
        bytecode = type(KillSwitchValidator).creationCode; 
        (success, returnData) = DETERMINISTIC_CREATE2_FACTORY.call(abi.encodePacked(bytecode));
        require(success, "Failed to deploy KillSwitchValidator");
        address validator = address(bytes20(returnData));
        console.log("KillSwitchValidator deployed at: %s", validator);
        
        bytecode = type(KillSwitchAction).creationCode; 
        (success, returnData) = DETERMINISTIC_CREATE2_FACTORY.call(abi.encodePacked(bytecode, abi.encode(KillSwitchValidator(validator))));
        require(success, "Failed to deploy KillSwitchAction");
        address action = address(bytes20(returnData));
        console.log("KillSwitchAction deployed at: %s", action);
        vm.stopBroadcast();
    }
}