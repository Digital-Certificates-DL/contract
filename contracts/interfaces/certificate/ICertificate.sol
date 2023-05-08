// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface ICertificate {
    struct CertificateInitParams {
        string description;
        string symbol;
        string name;
    }

    function safeMint(address to, string memory uri) external onlyOwner returns (uint256);

    function transferToken(address from, address to, uint tokenId) external onlyOwner;

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal override(ERC721);

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable);

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage);

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory);

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool);

    function setNewAdmin(address admin) external onlyOwner;

    function deleteAdmin(address admin) external onlyOwner;

    event mint(address _to, uint256 tokenId);
}
