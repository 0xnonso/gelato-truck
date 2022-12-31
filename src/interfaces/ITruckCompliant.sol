// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITruckCompliant {
    function canExecute() external returns(bool);
    function execute() external;
}