// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./vendored/Multicall3.sol";

contract GelatoTruck {
    using EnumerableSet for EnumerableSet.AddressSet;

    // CONSTANT VARS //

    ///target contract must be truck compliant!
    ///@dev target contract must implement `canExecute()` which returns a boolean value that indicates whether certain conditions are met
    ///@notice `canExecute()` function selector
    bytes4 public constant CAN_EXEC_SELECTOR = 0x78b90337;
    ///@dev target contract must implement `execute()`
    ///@notice `execute()` function selector
    bytes4 public constant EXEC_SELECTOR = 0x61461954;

    // IMMUTABLE VARS //
    
    ///@notice Contract owner
    address public immutable truckOwner;
    ///@notice Multicall contract implementation
    Multicall3 public immutable multicall;

    // INTERNAL VARS //

    ///@notice All targets - contracts to automate
    EnumerableSet.AddressSet internal flavours;
    ///mapping(Maestro -> bool)
    mapping(address => bool) internal isMaestro;

    // MODIFIERS //

    modifier onlyMaestro(){
        require(isMaestro[msg.sender], "Caller_Not_Maestro");
        _;
    }
    modifier onlyTruckOwner(){
        require(msg.sender == truckOwner, "Caller_Not_TruckOwner");
        _;
    }

    // EVENTS //

    event FlavourAdded(address _flavour);
    event FlavourRemoved(address _flavour);

    // CONSTRUCTOR //

    constructor(address _multicall){
        multicall = Multicall3(_multicall);
        isMaestro[msg.sender] = true;
        truckOwner = msg.sender;
    }
    
    // PUBLIC FUNCTIONS //

    ///@dev Add Maestro. Can only be done by the `truckOwner`
    function approveMaestro(address _maestro) public onlyTruckOwner(){
        require(!isMaestro[_maestro], "Already_Maestro");
        isMaestro[_maestro] = true;
    }

    ///@dev Revoke Maestro. Can only be done by the `truckOwner`
    function revokeMaestro(address _maestro) public onlyTruckOwner(){
        require(isMaestro[_maestro], "Not_Maestro");
        isMaestro[_maestro] = false;
    }

    ///@dev Add target
    ///@param _flavour target - Contract to automate
    function addFlavour(address _flavour) public onlyMaestro(){
        require(_flavour != address(0), "Address_0");
        flavours.add(_flavour);
        emit FlavourAdded(_flavour);
    }

    ///@dev Remove target. Can only be done by the `truckOwner`
    ///@param _flavour target - Contract to automate
    function removeFlavour(address _flavour) public onlyTruckOwner(){
        require(_flavour != address(0), "Address_0");
        flavours.remove(_flavour);
        emit FlavourRemoved(_flavour);
    }

    // EXTERNAL FUNCTIONS //

    ///@dev Execute all executable targets. If any errors or failures is encountered, call fails silently
    function freeze() external {
        if(canFreeze()){
            address[] memory _availableFlavoursToFreeze = availableFlavoursToFreeze();
            uint256 _availableFlavoursToFreezeLen = _availableFlavoursToFreeze.length;
            Multicall3.Call[] memory calls;
            for(uint256 i; i < _availableFlavoursToFreezeLen;){
                calls[i].target = _availableFlavoursToFreeze[i];
                calls[i].callData = abi.encode(EXEC_SELECTOR);
                unchecked { i++; }
            }
            multicall.tryAggregate(false, calls);
        }
    }

    // VIEW FUNCTIONS //

    ///@dev Indicates whether a target can be executed
    ///@return bool
    function canFreeze() public view returns(bool){
        return availableFlavoursToFreeze().length != 0;
    }

    ///@dev Returns all targets that can be executed
    ///@return _availableFlavoursToFreeze
    function availableFlavoursToFreeze() internal view returns(address[] memory _availableFlavoursToFreeze){
        address[] memory _flavours = getAllFlavours();
        uint256 _flavoursLen = _flavours.length;
        uint256 index;
        for(uint256 i; i < _flavoursLen;){
            address flavour = _flavours[i];
            (bool success, bytes memory returnData) = flavour.staticcall(abi.encode(CAN_EXEC_SELECTOR));
            bool returnValue = abi.decode(returnData, (bool));
            if(success && returnValue){
                _availableFlavoursToFreeze[index] = flavour;
                index++;
            }
            unchecked { i++; }
        }
    }

    ///@dev Returns all targets
    function getAllFlavours() internal view returns(address[] memory){
        return flavours.values();
    }

}