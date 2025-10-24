// SPDX-License-Identifier: MIT

// Layout of Script:
// version
// imports
// interfaces, libraries, contracts

// Layout of Contract Elements:
// errors
// Type declarations
// State variables
// Events
// Modifiers

// Functions
// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure function

/////////*version: 1.0.0*//////////
pragma solidity ^0.8.24;

////////*imports*//////////
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @dev A simple ERC20 token that supports rebasing.
 */

////////*contracts*//////////
contract RebaseToken is ERC20, Ownable, AccessControl {
    ////////*errors*//////////
    error RebaseToken_InterestRateCanOnlyDecrease(uint256 oldRate, uint256 newRate);

    ////////*state variables*//////////
    /**
     * @notice s_ = Storage/State Variables
     * @notice i_ = Immutable Variables
     * @notice c_ = Constants
     */
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e10;
    uint256 private constant PRECISION_FACTOR = 1e18;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;
    /// @notice this is the 1 in blockchain world

    //using keccak256 to define role for minting and burning
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    ////////*events*//////////

    event InterestRateSetted(uint256 newRate);

    ////////*constructor*//////////
    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    ////////*external functions*//////////

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }
    /**
     * @notice Sets the interest rate for the token.
     * @param _newRate The new interest rate to be set.
     * @dev The interest rate can only be decreased.
     */

    function setInterestRate(uint256 _newRate) external onlyOwner {
        if (_newRate > s_interestRate) {
            revert RebaseToken_InterestRateCanOnlyDecrease(s_interestRate, _newRate);
        }
        s_interestRate = _newRate;
        emit InterestRateSetted(_newRate);
    }

    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        // Update the user's accrued interest before minting new tokens,giveing them their due interest
        _mintAccruedInterest(_to);
        // Set the user's interest rate to the current interest rate at the time of minting
        //timestamp is also updated in _mintAccruedInterest
        s_userInterestRate[_to] = _userInterestRate; //the unit of it to caculate interest is by second
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user's tokens when they withdraw from the vault
     * @dev i'v ajusted _mintAccruedInterest to be called before _burn, so the user gets their interest before burning
     * @dev get to test cases to verify this works as intended
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        //first mint the accrued interest to the user before calculating burn amount
        _mintAccruedInterest(_from);

        //if _amount is max uint256, burn all tokens (after interest is minted)
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }

        _burn(_from, _amount);
    }

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

    /// @notice Returns the current interest rate for the token.
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /// @notice Returns the user's principal balance (excluding accrued interest).
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /////////*public functions*//////////
    function balanceOf(address _user) public view override returns (uint256) {
        //_calculateUserAccumulatedInterestSinceLastUpdate returns a factor with PRECISION_FACTOR base
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
    }

    /// @notice adjusted transfer to mint accrued interest to both sender and recipient before transfer
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        //first mint accrued interest to both sender and recipient, so their balances are up to date
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        //if recipient is a new user, set their interest rate to the sender's interest rate
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        //first mint accrued interest to both sender and recipient, so their balances are up to date
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        //if recipient is a new user, set their interest rate to the sender's interest rate
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    ////////*internal functions*//////////

    /**
     * @notice Mints accrued interest tokens to the user.
     */
    function _mintAccruedInterest(address _user) internal {
        //find current balance of rebase tokens have been minted to the user
        uint256 previousBalance = super.balanceOf(_user);
        //calculate accrued interest based on time elapsed and difference in interest rates
        //the accrued interest and new balance
        uint256 currentBalance = balanceOf(_user);
        //calculate the number of tokens that need to be minted to the user
        uint256 interestToMint = currentBalance - previousBalance;
        //call _mint to mint the tokens to the user
        _mint(_user, interestToMint);
        //so the last updated timestamp is updated to now
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256) {
        //calculate the accrued interest based on time elapsed and difference in interest rates
        //it is (principal) * (rate) * (time) + (principal)
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];

        /// @notice need to add 1e18 base to the linear interest calculation */
        uint256 linearInterest = (s_userInterestRate[_user] * timeElapsed) + PRECISION_FACTOR;

        return linearInterest;
    }
}
