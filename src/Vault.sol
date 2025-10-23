//SPDX-License-Identifier: MIT

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

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

/////////*contracts*//////////

contract Vault {
    // 1.pass the token address to the constructor
    // 2.deposit function: mint tokens to the user
    // 3.withdraw function: burn tokens from the user,send ether back to the user
    // create a way to add rewards to the vault

    ////////*errors*//////////
    error Vault_RedeemFailed();

    IRebaseToken private immutable i_rebaseToken;

    /////////*events*//////////
    event Redeem(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);

    ////////*constructor*//////////
    //pass the token address to the constructor
    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    // receive function to accept ETH deposits
    receive() external payable {}

    //deposit function
    /// @notice payable deposit function to mint rebase tokens,so we don't need specify amount and token address
    function deposit() external payable {
        i_rebaseToken.mint(msg.sender, msg.value);
    }

    function redeem(uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }

        //burn rebase tokens from the user
        i_rebaseToken.burn(msg.sender, _amount);
        //send ether back to the user
        //msg.sender call method to receive ether from the contract
        //{value: _amount} to specify the amount of ether to send
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault_RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
