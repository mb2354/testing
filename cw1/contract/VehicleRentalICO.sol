// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import statements
import "./VehicleRentalToken.sol";

// Contracts

/// @title VehicleRentalICO
/// @notice Handles the Initial Coin Offering (ICO) for the Vehicle Rental Token
contract VehicleRentalICO {
    // Private variables
    VehicleRentalToken private tokenContract;
    address private owner;
    uint256 private constant TOKEN_PRICE = 1 ether; // 1 Token = 1 Ether
    uint256 private tokensSold;

    mapping(address => uint256) private buyerBalances;

    
    event TokensPurchased(address indexed buyer, uint256 amount);
    event ICOEnded(address indexed owner, uint256 totalTokensSold);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    
    error NotOwner();
    error InsufficientTokens(uint256 requested, uint256 available);
    error InvalidPurchaseAmount();

    /// @notice Modifier to require the contract owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    /// @notice Constructor to initialize the ICO contract
    /// @param _tokenAddress Address of the VehicleRentalToken contract
    constructor(address _tokenAddress) {
        tokenContract = VehicleRentalToken(_tokenAddress);
        owner = msg.sender;
    }

    /// @notice Purchase tokens during the ICO
    /// @param _amount Amount of tokens to purchase
    function buyTokens(uint256 _amount) external payable {
        // Calculate the total Ether required for the purchase
        uint256 requiredEther = _amount * TOKEN_PRICE;

        // Check if the buyer has enough Ether to pay for the purchase
        if (msg.value != requiredEther) {
            revert InvalidPurchaseAmount();
        }

        // Check if there are enough tokens available for purchase
        uint256 availableTokens = tokenContract.balanceOf(address(this));
        if (_amount > availableTokens) {
            revert InsufficientTokens(_amount, availableTokens);
        }

        // Update the state
        tokensSold += _amount;
        buyerBalances[msg.sender] += _amount;

        // Transfer tokens to the buyer
        tokenContract.transfer(msg.sender, _amount);

        emit TokensPurchased(msg.sender, _amount);
    }

    /// @notice Ends the ICO and transfers remaining tokens back to the owner
    function endICO() external onlyOwner {
        uint256 remainingTokens = tokenContract.balanceOf(address(this));
        if (remainingTokens > 0) {
            tokenContract.transfer(owner, remainingTokens);
        }

        emit ICOEnded(owner, tokensSold);
    }

    /// @notice Withdraw Ether collected from the ICO
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner).transfer(balance);

        emit FundsWithdrawn(owner, balance);
    }

    /// @notice Get the number of tokens purchased by a buyer
    /// @param _buyer Address of the buyer
    /// @return The number of tokens purchased
    function getBuyerBalance(address _buyer) external view returns (uint256) {
        return buyerBalances[_buyer];
    }

    /// @notice Get the total tokens sold during the ICO
    /// @return The total tokens sold
    function getTotalTokensSold() external view returns (uint256) {
        return tokensSold;
    }
}
