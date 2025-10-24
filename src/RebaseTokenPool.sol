/// @notice RebaseTokenPool is a contract that manages a pool of rebase tokens, interact with CCIP?
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {Pool} from "@ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract RebaseTokenPool is TokenPool {
    constructor(IERC20 _token, address[] memory _allowlist, address _rnmProxy, address _router)
        TokenPool(_token, _allowlist, _rnmProxy, _router)
    {}
    //LocalOrBurn is call from local chain token pool to lock or burn tokens

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == Pool.CCIP_POOL_V1 || super.supportsInterface(interfaceId);
    }

    function lockOrBurn(Pool.LockOrBurnInV1 calldata lockOrBurnIn)
        external
        returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut)
    {
        //this is risk managment step, validate the lockOrBurnIn data
        _validateLockOrBurn(lockOrBurnIn);
        //i_token is _token from TokenPool(TokenPool's constructor)
        address tokenSender = lockOrBurnIn.originalSender;
        uint256 userInterestRate = IRebaseToken(address(i_token)).getUserInterestRate(tokenSender);
        //token has been send to the TokenPool contract by the user before calling lockOrBurn
        //so we can just burn the tokens from the user,but address this is the TokenPool contract address

        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);
        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
            destPoolData: abi.encode(userInterestRate)
        });
    }

    //ReleaseOrMint is call from remote chain token pool to release or mint tokens
    function releaseOrMint(Pool.ReleaseOrMintInV1 calldata releaseOrMintIn)
        external
        returns (Pool.ReleaseOrMintOutV1 memory releaseOrMintOut)
    {
        //this is risk managment step, validate the releaseOrMintIn data
        _validateReleaseOrMint(releaseOrMintIn);
        uint256 userInterestRate = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));
        IRebaseToken(address(i_token)).mint(releaseOrMintIn.receiver, releaseOrMintIn.amount, userInterestRate);
        //so no i'm clear that in and out are both needed, for data require and passout
        return Pool.ReleaseOrMintOutV1({destinationAmount: releaseOrMintIn.amount});
    }
}
