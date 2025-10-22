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
        rebaseToken = new RebaseToken();
        //deploy vault with rebaseToken address, rebaseToken should implement IRebaseToken, so we can pass its address to the vault
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        //grant vault the minter role in rebaseToken
        rebaseToken.grantMintAndBurnRole(address(vault));
        
        (bool success,) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();



    }
}