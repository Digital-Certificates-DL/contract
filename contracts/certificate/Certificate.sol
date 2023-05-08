// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";
import "../interfaces/certificate/ICertificate.sol";
import "@dlsl/dev-modules/contracts-registry/AbstractDependant.sol";

contract Certificate is
    ICertificate,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    AbstractDependant,
    Initializable
{
    using Counters for Counters.Counter;

    mapping(address => bool) private owners;

    Counters.Counter private _tokenIdCounter;

    modifier onlyOwner() {
        require(owners[msg.sender], "permission denied");
        _;
    }

    function __Certificate_init(CertificateInitParams calldata params_) external initializer {
        description = params_.description;
        version = params_.version;
        owners[msg.sender] = true;
        ERC721(params_.name, params_.symbol);
        owners[msg.sender] = true;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function safeMint(address to, string memory uri) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function transferToken(address from, address to, uint tokenId) external onlyOwner {
        transferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyOwner {
        _transfer(from, to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal override(ERC721) {
        _mint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        require(owners[msg.sender], "permission denied");

        if (batchSize > 1) {
            revert("ERC721Enumerable: consecutive transfers not supported");
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setNewAdmin(address admin) external onlyOwner {
        owners[admin] = true;
    }

    function deleteAdmin(address admin) external onlyOwner {
        delete owners[admin];
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
