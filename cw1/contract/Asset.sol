// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title Asset Management Contract
/// @notice Manages vehicle assets for the Vehicle Rental System
contract Asset {
    
    // Type declarations
    enum VehicleCategory { Car, Bike, Van }

    struct Vehicle {
        uint256 vehicleId;
        address owner;
        VehicleCategory category;
        uint256 rentalPrice;
        bool isAvailable;
        uint256 maintenanceDueDate;
        bool hasInsurance;
    }

    
    uint256 private vehicleCounter;
    mapping(uint256 => Vehicle) private vehicles;

    
    event VehicleRegistered(uint256 indexed vehicleId, address indexed owner, VehicleCategory category);
    event VehicleUpdated(uint256 indexed vehicleId, uint256 rentalPrice, bool isAvailable, bool hasInsurance);
    event OwnershipTransferred(uint256 indexed vehicleId, address indexed newOwner);

    
    error NotOwner(uint256 vehicleId);
    error InvalidCategory();

    
    modifier onlyOwner(uint256 _vehicleId) {
        if (vehicles[_vehicleId].owner != msg.sender) {
            revert NotOwner(_vehicleId);
        }
        _;
    }

    /// @notice Registers a new vehicle
    /// @param _category The category of the vehicle (Car, Bike, Van)
    /// @param _rentalPrice The rental price per day for the vehicle
    /// @param _maintenanceDueDate The next maintenance due date
    function registerVehicle(
        VehicleCategory _category,
        uint256 _rentalPrice,
        uint256 _maintenanceDueDate
    ) external {
        if (uint256(_category) >= 3) {
            revert InvalidCategory();
        }

        vehicleCounter++;
        vehicles[vehicleCounter] = Vehicle({
            vehicleId: vehicleCounter,
            owner: msg.sender,
            category: _category,
            rentalPrice: _rentalPrice,
            isAvailable: true,
            maintenanceDueDate: _maintenanceDueDate,
            hasInsurance: false
        });

        emit VehicleRegistered(vehicleCounter, msg.sender, _category);
    }

    /// @notice Updates vehicle details
    /// @param _vehicleId The ID of the vehicle to update
    /// @param _rentalPrice New rental price for the vehicle
    /// @param _isAvailable Updated availability status
    /// @param _hasInsurance Updated insurance status
    function updateVehicle(
        uint256 _vehicleId,
        uint256 _rentalPrice,
        bool _isAvailable,
        bool _hasInsurance
    ) external onlyOwner(_vehicleId) {
        Vehicle storage vehicle = vehicles[_vehicleId];
        vehicle.rentalPrice = _rentalPrice;
        vehicle.isAvailable = _isAvailable;
        vehicle.hasInsurance = _hasInsurance;

        emit VehicleUpdated(_vehicleId, _rentalPrice, _isAvailable, _hasInsurance);
    }

    /// @notice Transfers ownership of a vehicle to a new owner
    /// @param _vehicleId The ID of the vehicle to transfer
    /// @param _newOwner Address of the new owner
    function transferOwnership(uint256 _vehicleId, address _newOwner) external onlyOwner(_vehicleId) {
        vehicles[_vehicleId].owner = _newOwner;

        emit OwnershipTransferred(_vehicleId, _newOwner);
    }

    /// @notice Fetches details of a vehicle
    /// @param _vehicleId The ID of the vehicle
    /// @return Vehicle struct containing vehicle details
    function getVehicle(uint256 _vehicleId) external view returns (Vehicle memory) {
        return vehicles[_vehicleId];
    }

    /// @notice Checks if a vehicle is available for rental
    /// @param _vehicleId The ID of the vehicle
    /// @return Boolean indicating availability
    function isAvailable(uint256 _vehicleId) external view returns (bool) {
        return vehicles[_vehicleId].isAvailable;
    }
}
