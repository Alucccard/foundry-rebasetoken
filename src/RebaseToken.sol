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

/**
 * @title RebaseToken
* @dev A simple ERC20 token that supports rebasing.
*/

////////*contracts*//////////
contract RebaseToken is ERC20 {

    ////////*errors*//////////
    error RebaseToken_InterestRateCanOnlyDecrease(uint256 oldRate, uint256 newRate);
    
    ////////*state variables*//////////
    /**
    * @notice s_ = Storage/State Variables
    * @notice i_ = Immutable Variables
    * @notice c_ = Constants
    */
    uint256 private s_interestRate = 5e10; //number of parts per 1e18, so 5e10 = 0.00000005 = 0.000005% per second
    mapping (address => uint256) private s_userInterestRate;
    mapping (address => uint256) private s_userLastUpdatedTimestamp;
    /// @notice this is the 1 in blockchain world
    uint256 private constant PRECISION_FACTOR = 1e18;

    ////////*events*//////////
    event InterestRateSetted(uint256 newRate);

    ////////*constructor*//////////
    constructor() ERC20("Rebase Token", "RBT") {}

    ////////*external functions*//////////
    /**
    * @notice Sets the interest rate for the token.
    * @param _newRate The new interest rate to be set.
    * @dev The interest rate can only be decreased.
    */
    function setInterestRate(uint256 _newRate) external {
        if (_newRate > s_interestRate) {
            revert RebaseToken_InterestRateCanOnlyDecrease(s_interestRate, _newRate);
        }
        s_interestRate = _newRate;
        emit InterestRateSetted(_newRate);
    }

    function mint(address _to, uint256 _amount) external {
        // Update the user's accrued interest before minting new tokens
        _mintAccruedInterest(_to);
        // Set the user's interest rate to the current interest rate at the time of minting
        s_userInterestRate[_to] = s_interestRate; //the unit of it to caculate interest is by second
        _mint(_to, _amount);
    }

    function getUserInterestRate(address _user) external view returns (uint256){
        return s_userInterestRate[_user];
    }
    
    /////////*public functions*//////////
    function balanceOf(address _user) public view override returns (uint256) {
        //_calculateUserAccumulatedInterestSinceLastUpdate returns a factor with PRECISION_FACTOR base
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
    }

    ////////*internal functions*//////////
    function _mintAccruedInterest(address _user) internal{
        //find current balance of rebase tokens have been minted to the user
        //calculate accrued interest based on time elapsed and difference in interest rates
        //calculate the number of tokens that need to be minted to the user
        //call _mint to mint the tokens to the user
        s_userLastUpdatedTimestamp[_user] = block.timestamp;//so the last updated timestamp is updated to now
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256){
        //calculate the accrued interest based on time elapsed and difference in interest rates
        //it is (principal) * (rate) * (time) + (principal)
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];

        
        /// @notice need to add 1e18 base to the linear interest calculation */
        uint256 linearInterest = (s_userInterestRate[_user] * timeElapsed) + PRECISION_FACTOR;


        return linearInterest;
    }

}   