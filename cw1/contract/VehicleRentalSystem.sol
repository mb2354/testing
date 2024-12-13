// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import statements
import "./Asset.sol";
import "./VehicleRentalToken.sol";
import "./Insurance.sol";

// Contracts

/// @title Vehicle Rental System
/// @notice Implements the core functionality for vehicle rentals
contract VehicleRentalSystem {
    

    struct Rental {
        uint256 rentalId;
        address renter;
        uint256 vehicleId;
        uint256 startDate;
        uint256 endDate;
        uint256 escrowAmount;
        bool isCompleted;
    }


    Asset private assetContract;
    VehicleRentalToken private tokenContract;
    Insurance private insuranceContract;
    uint256 private rentalCounter;
    address private admin;

    mapping(uint256 => Rental) private rentals;

   
    event RentalInitiated(
        uint256 indexed rentalId,
        address indexed renter,
        uint256 indexed vehicleId,
        uint256 escrowAmount,
        uint256 startDate,
        uint256 endDate
    );

    event RentalCompleted(uint256 indexed rentalId, address indexed renter, uint256 indexed vehicleId);

    event DisputeRaised(uint256 indexed rentalId, address indexed renter);

    event DisputeResolved(uint256 indexed rentalId, bool refundToRenter);

   
    error NotAdmin();
    error NotRenter(uint256 rentalId);
    error RentalAlreadyCompleted(uint256 rentalId);
    error VehicleNotAvailable(uint256 vehicleId);
    error InsuranceRequired(uint256 vehicleId);

  
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    modifier onlyRenter(uint256 _rentalId) {
        if (rentals[_rentalId].renter != msg.sender) {
            revert NotRenter(_rentalId);
        }
        _;
    }

    /// @notice Constructor for VehicleRentalSystem
    /// @param _assetAddress Address of the Asset contract
    /// @param _tokenAddress Address of the VehicleRentalToken contract
    /// @param _insuranceAddress Address of the Insurance contract
    constructor(
        address _assetAddress,
        address _tokenAddress,
        address _insuranceAddress
    ) {
        assetContract = Asset(_assetAddress);
        tokenContract = VehicleRentalToken(_tokenAddress);
        insuranceContract = Insurance(_insuranceAddress);
        admin = msg.sender;
    }

    /// @notice Initiates a rental for a vehicle
    /// @param _vehicleId ID of the vehicle to be rented
    /// @param _rentalDays Number of days for the rental
    function initiateRental(uint256 _vehicleId, uint256 _rentalDays) external {
        Asset.Vehicle memory vehicle = assetContract.getVehicle(_vehicleId);

        if (!vehicle.isAvailable) {
            revert VehicleNotAvailable(_vehicleId);
        }

        if (!insuranceContract.hasActivePolicy(_vehicleId)) {
            revert InsuranceRequired(_vehicleId);
        }

        uint256 rentalFee = vehicle.rentalPrice * _rentalDays;
        tokenContract.transferFrom(msg.sender, address(this), rentalFee);

        rentalCounter++;
        rentals[rentalCounter] = Rental({
            rentalId: rentalCounter,
            renter: msg.sender,
            vehicleId: _vehicleId,
            startDate: block.timestamp,
            endDate: block.timestamp + (_rentalDays * 1 days),
            escrowAmount: rentalFee,
            isCompleted: false
        });

        assetContract.updateVehicle(_vehicleId, vehicle.rentalPrice, false, vehicle.hasInsurance);

        emit RentalInitiated(rentalCounter, msg.sender, _vehicleId, rentalFee, block.timestamp, block.timestamp + (_rentalDays * 1 days));
    }

    /// @notice Completes a rental
    /// @param _rentalId ID of the rental to complete
    function completeRental(uint256 _rentalId) external onlyRenter(_rentalId) {
        Rental storage rental = rentals[_rentalId];

        if (rental.isCompleted) {
            revert RentalAlreadyCompleted(_rentalId);
        }

        if (block.timestamp < rental.endDate) {
            revert("Rental period not over");
        }

        rental.isCompleted = true;

        Asset.Vehicle memory vehicle = assetContract.getVehicle(rental.vehicleId);
        tokenContract.transfer(vehicle.owner, rental.escrowAmount);

        assetContract.updateVehicle(rental.vehicleId, vehicle.rentalPrice, true, vehicle.hasInsurance);

        emit RentalCompleted(_rentalId, rental.renter, rental.vehicleId);
    }

    /// @notice Raises a dispute for a rental
    /// @param _rentalId ID of the rental in dispute
    function raiseDispute(uint256 _rentalId) external onlyRenter(_rentalId) {
        emit DisputeRaised(_rentalId, msg.sender);
    }

    /// @notice Resolves a dispute
    /// @param _rentalId ID of the rental in dispute
    /// @param _refundToRenter Boolean indicating whether to refund the renter
    function resolveDispute(uint256 _rentalId, bool _refundToRenter) external onlyAdmin {
        Rental storage rental = rentals[_rentalId];

        if (_refundToRenter) {
            tokenContract.transfer(rental.renter, rental.escrowAmount);
        } else {
            Asset.Vehicle memory vehicle = assetContract.getVehicle(rental.vehicleId);
            tokenContract.transfer(vehicle.owner, rental.escrowAmount);
        }

        rental.isCompleted = true;

        emit DisputeResolved(_rentalId, _refundToRenter);
    }

    /// @notice Fetches rental details
    /// @param _rentalId ID of the rental
    /// @return Rental details
    function getRental(uint256 _rentalId) external view returns (Rental memory) {
        return rentals[_rentalId];
    }
}
