// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/Ownable.sol";


/**
 * @title UfoZiom Token
 * @dev UfoZiom Token is an ERC20 token with a transaction fee for burning.
 */
contract UfoZiomToken is ERC20, Ownable {
    // Address where burnt tokens are sent (dead address)
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Transaction fee in percentage (e.g., 2 means 2%)
    uint256 public taxFee = 2;

    // Mapping of addresses excluded from fees (e.g., owner, exchanges)
    mapping(address => bool) private _isExcludedFromFee;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens and excludes owner from fee.
     */
    constructor() ERC20("UfoZiom Token", "UFO") {
        // Mint total supply to contract deployer
        _mint(msg.sender, 1_000_000_000_000 * 10 ** decimals());

        // Exclude owner from fees
        _isExcludedFromFee[msg.sender] = true;
    }

    /**
     * @dev Exclude an account from transaction fees.
     * Can only be called by the owner.
     * @param account The address to exclude.
     */
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @dev Include an account in transaction fees.
     * Can only be called by the owner.
     * @param account The address to include.
     */
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @dev Set the transaction fee percentage.
     * Can only be called by the owner.
     * @param fee The new fee percentage.
     */
    function setTaxFeePercent(uint256 fee) external onlyOwner {
        require(fee >= 0 && fee <= 10, "Fee must be between 0% and 10%");
        taxFee = fee;
    }

    /**
     * @dev Overrides the default ERC20 _transfer function to implement transaction fee.
     * @param sender The address transferring tokens.
     * @param recipient The address receiving tokens.
     * @param amount The amount of tokens being transferred.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            // If either sender or recipient is excluded from fee, transfer tokens without fee
            super._transfer(sender, recipient, amount);
        } else {
            // Calculate the fee amount
            uint256 feeAmount = amount * taxFee / 100;
            uint256 amountAfterFee = amount - feeAmount;

            // Burn the fee amount
            super._transfer(sender, burnAddress, feeAmount);

            // Transfer the remaining amount to the recipient
            super._transfer(sender, recipient, amountAfterFee);
        }
    }
}
