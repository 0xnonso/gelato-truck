// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;
import "./interfaces/IResolver.sol";
import "./interfaces/OpsReady.sol";
import "./GelatoTruck.sol";

contract TruckResolver is OpsReady, IResolver {
    GelatoTruck public immutable gelatoTruck;

    constructor(
        address _gelatoTruck, 
        address _ops
    ) OpsReady(_ops){
        gelatoTruck = GelatoTruck(_gelatoTruck);
    }

    //Start Task
    function startTask() external {
        IOps(ops).createTask(
            address(gelatoTruck), 
            gelatoTruck.freeze.selector,
            address(this),
            abi.encodeWithSelector(this.checker.selector)
        );
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        canExec = gelatoTruck.canFreeze();
        execPayload = abi.encodeWithSelector(
            gelatoTruck.freeze.selector
        );
    }

}