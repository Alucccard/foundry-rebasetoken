// SPDX-License-Identifier: MIT
/////////*version: 1.0.0*//////////
pragma solidity ^0.8.24;

////////*imports*//////////
import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";

import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";

/////////*contracts*//////////
contract RebaseTokenTest is Test {
    RebaseToken private rebaseToken;
    Vault private vault;

    //users for testing
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        vm.deal(owner, 1e18);
        rebaseToken = new RebaseToken();
        //deploy vault with rebaseToken address, rebaseToken should implement IRebaseToken, so we can pass its address to the vault
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        //grant vault the minter role in rebaseToken
        rebaseToken.grantMintAndBurnRole(address(vault));

        (bool success,) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
    }

    function addRewardsToVault(uint256 rewardAmount) public {
        (bool success,) = payable(address(vault)).call{value: rewardAmount}("");
    }

    function testDepositLinear(uint256 amount) public {
        vm.assume(amount > 1e5);
        amount = bound(amount, 1e5, type(uint96).max);
        //1.deposit 1 ether to the vault
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        //2.check the rebaseToken balance of user
        uint256 startBalance = rebaseToken.balanceOf(user);
        console.log("startBalance:", startBalance);
        assertApproxEqAbs(startBalance, amount, 1e10); //allow small difference due to rounding
        //3.warp time by 1 hour
        vm.warp(block.timestamp + 365 days);
        uint256 middleBalance = rebaseToken.balanceOf(user);
        assertGt(middleBalance, startBalance);
        //4.warp time by another 1 hour
        vm.warp(block.timestamp + 365 days);
        uint256 endBalance = rebaseToken.balanceOf(user);
        assertGt(endBalance, middleBalance);

        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1e10);
        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        //1.deposit amount ether to the vault
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        assertEq(rebaseToken.balanceOf(user), amount);
        //2.redeem immediately
        vault.redeem(type(uint256).max);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        //the function of bound is to limit the value of depositAmount when testing lanuched
        //and the depositAmount value will be created automaticlly by foundry test tool
        depositAmount = bound(depositAmount, 1e18, type(uint96).max);
        // Bound time to reasonable values (max 10 years to prevent overflow)
        time = bound(time, 1 hours, 365 days * 10);
        //1.deposit a amount to the vault
        vm.prank(user);
        vm.deal(user, depositAmount);
        /// @notice the deposit function is payable,so the syntax is we see below
        vault.deposit{value: depositAmount}();
        //2.warp the time
        vm.warp(block.timestamp + time);
        uint256 balanceAfterTime = rebaseToken.balanceOf(user);
        //2.2 add rewards to the vault to simulate interest accrual
        vm.deal(owner, balanceAfterTime - depositAmount);
        vm.prank(owner);
        addRewardsToVault(balanceAfterTime - depositAmount);
        //3.redeem
        vm.prank(user);
        vault.redeem(type(uint256).max);

        uint256 ethBalance = address(user).balance;
        assertEq(ethBalance, balanceAfterTime);
        assertGt(ethBalance, depositAmount);
    }
}
