// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/GelatoTruck.sol";
import "../src/TruckResolver.sol";

contract Deploy is Script {
    GelatoTruck internal gelatoTruck;
    TruckResolver internal truckResolver;

    address public constant ops = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;
    address public constant multicall = 0xcA11bde05977b3631167028862bE2a173976CA11;

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        gelatoTruck = new GelatoTruck(multicall);
        truckResolver = new TruckResolver(
            address(gelatoTruck),
            ops
        );
        truckResolver.startTask();

        vm.broadcast();
    }
}
