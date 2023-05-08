// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICertificate is IERC721, IERC721Enumerable {
    struct CertificateInitParams {
        string description;
        address certificateTokenAddr;
        uint256 version;
    }

    event OraclesUpdated(address[] oraclesToUpdate, bool isAdding);
}
