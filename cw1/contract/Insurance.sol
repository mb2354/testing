// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Insurance Management Contract
/// @notice Manages insurance policies for vehicles in the Vehicle Rental System
contract Insurance {

    
    struct Policy {
        uint256 policyId;
        address vehicleOwner;
        uint256 vehicleId;
        uint256 premium; 
        uint256 coverageAmount; 
        uint256 expirationDate;
        bool isActive;
    }

    
    uint256 private policyCounter;
    mapping(uint256 => Policy) private policies;
    mapping(uint256 => uint256) private vehicleToPolicy;

    /// @notice Emitted when a new insurance policy is purchased
    event PolicyPurchased(
        uint256 indexed policyId,
        address indexed vehicleOwner,
        uint256 indexed vehicleId,
        uint256 premium,
        uint256 coverageAmount,
        uint256 expirationDate
    );

    event PolicyClaimed(uint256 indexed policyId, uint256 claimAmount);
    event PolicyCancelled(uint256 indexed policyId);

    
    error NotPolicyOwner(uint256 policyId);
    error PolicyNotActive(uint256 policyId);
    error ClaimExceedsCoverage(uint256 claimAmount, uint256 coverageRemaining);
    error PolicyExpired(uint256 policyId);


    modifier onlyPolicyOwner(uint256 _policyId) {
        if (policies[_policyId].vehicleOwner != msg.sender) {
            revert NotPolicyOwner(_policyId);
        }
        _;
    }

    modifier onlyActivePolicy(uint256 _policyId) {
        if (!policies[_policyId].isActive) {
            revert PolicyNotActive(_policyId);
        }
        _;
    }

    /// @notice Purchases an insurance policy for a vehicle
    /// @param _vehicleId The ID of the vehicle being insured
    /// @param _premium The premium amount in ETH
    /// @param _coverageAmount The maximum coverage amount in ETH
    /// @param _duration The duration of the policy in seconds
    function purchasePolicy(
        uint256 _vehicleId,
        uint256 _premium, 
        uint256 _coverageAmount, 
        uint256 _duration
    ) external payable {
        uint256 premiumInWei = _premium * 1 ether;
        uint256 coverageAmountInWei = _coverageAmount * 1 ether;

        
        require(msg.value == premiumInWei, "Incorrect premium amount");

        policyCounter++;
        policies[policyCounter] = Policy({
            policyId: policyCounter,
            vehicleOwner: msg.sender,
            vehicleId: _vehicleId,
            premium: premiumInWei,
            coverageAmount: coverageAmountInWei,
            expirationDate: block.timestamp + _duration,
            isActive: true
        });

        vehicleToPolicy[_vehicleId] = policyCounter;

        emit PolicyPurchased(
            policyCounter,
            msg.sender,
            _vehicleId,
            premiumInWei,
            coverageAmountInWei,
            block.timestamp + _duration
        );
    }

    /// @notice Claims an insurance policy
    /// @param _policyId The ID of the policy being claimed
    /// @param _claimAmount The amount being claimed in ETH
    function claimPolicy(uint256 _policyId, uint256 _claimAmount)
        external
        onlyPolicyOwner(_policyId)
        onlyActivePolicy(_policyId)
    {
        Policy storage policy = policies[_policyId];
        uint256 claimAmountInWei = _claimAmount * 1 ether;

        if (block.timestamp > policy.expirationDate) {
            revert PolicyExpired(_policyId);
        }

        if (claimAmountInWei > policy.coverageAmount) {
            revert ClaimExceedsCoverage(claimAmountInWei, policy.coverageAmount);
        }

        policy.coverageAmount -= claimAmountInWei;
        payable(policy.vehicleOwner).transfer(claimAmountInWei);

        emit PolicyClaimed(_policyId, claimAmountInWei);
    }

    /// @notice Cancels an insurance policy
    /// @param _policyId The ID of the policy being canceled
    function cancelPolicy(uint256 _policyId) external onlyPolicyOwner(_policyId) {
    Policy storage policy = policies[_policyId];
    require(policy.isActive, "Policy is already inactive");

    policy.isActive = false;

    emit PolicyCancelled(_policyId);
}


    /// @notice Retrieves the details of a policy
    /// @param _policyId The ID of the policy
    /// @return Policy details
    function getPolicy(uint256 _policyId) external view returns (Policy memory) {
        return policies[_policyId];
    }

    /// @notice Checks if a vehicle has an active policy
    /// @param _vehicleId The ID of the vehicle
    /// @return Boolean indicating if the vehicle has an active policy
    function hasActivePolicy(uint256 _vehicleId) external view returns (bool) {
    uint256 policyId = vehicleToPolicy[_vehicleId];
    Policy storage policy = policies[policyId];
    return policy.isActive && block.timestamp <= policy.expirationDate;
}

}
