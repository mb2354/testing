// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import statements
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";



/// @title VehicleRentalToken
/// @notice ERC-20 Token implementation for the Vehicle Rental System
contract VehicleRentalToken is ERC20, AccessControl {
    
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    uint256 private constant INITIAL_SUPPLY = 1_000_000 * (10 ** 18);

    
    event TokensBurned(address indexed burner, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);

    
    error InsufficientPermissions();


    modifier onlyMinter() {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert InsufficientPermissions();
        _;
    }

    /// @dev Constructor to initialize the token and assign roles
    /// @param _admin Address of the admin
    constructor(address _admin) ERC20("VehicleRentalToken", "VRT") {
    require(_admin != address(0), "Admin address cannot be zero");

    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    _grantRole(MINTER_ROLE, _admin);

    _mint(_admin, INITIAL_SUPPLY);
}


    /// @notice Mint new tokens
    /// @dev Can only be called by an account with MINTER_ROLE
    /// @param _to Address to receive the newly minted tokens
    /// @param _amount Amount of tokens to mint
    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
        emit TokensMinted(_to, _amount);
    }

    /// @notice Burn tokens from the caller's account
    /// @param _amount Amount of tokens to burn
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
        emit TokensBurned(msg.sender, _amount);
    }
}
