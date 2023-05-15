// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./interfaces/ITokenFactory.sol";
import "./interfaces/ITokenContract.sol";
import "./interfaces/IOwnable.sol";

contract TokenContract is ITokenContract, IOwnable, ERC721EnumerableUpgradeable {
    ITokenFactory public override tokenFactory;

    uint256 internal _tokenId;

    mapping(string => bool) public override existingTokenURIs;

    mapping(address => bool) private _localAdmins;
    mapping(uint256 => string) internal _tokenURIs;

    modifier onlyAdmin() {
        require(_localAdmins[msg.sender], "TokenContract: Only admin can call this function.");
        _;
    }

    function __TokenContract_init(
        TokenContractInitParams calldata initParams_
    ) external override initializer {
        __ERC721_init(initParams_.tokenName, initParams_.tokenSymbol);

        tokenFactory = ITokenFactory(initParams_.tokenFactoryAddr);

        _localAdmins[initParams_.admin] = true;
    }

    function mintToken(address to, string memory tokenURI_) external returns (uint256) {
        uint256 currentTokenId_ = _tokenId++;
        _mintToken(to, currentTokenId_, tokenURI_);

        emit SuccessfullyMinted(msg.sender, MintedTokenInfo(currentTokenId_, tokenURI_));
        return currentTokenId_;
    }

    function getUserTokenIDs(
        address userAddr_
    ) external view override returns (uint256[] memory tokenIDs_) {
        uint256 _tokensCount = balanceOf(userAddr_);

        tokenIDs_ = new uint256[](_tokensCount);

        for (uint256 i; i < _tokensCount; i++) {
            tokenIDs_[i] = tokenOfOwnerByIndex(userAddr_, i);
        }
    }

    function owner() public view override returns (address) {
        return IOwnable(address(tokenFactory)).owner();
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "TokenContract: URI query for nonexistent token.");

        string memory baseURI_ = _baseURI();

        return
            bytes(baseURI_).length > 0
                ? string(
                    abi.encodePacked(tokenFactory.baseTokenContractsURI(), _tokenURIs[tokenId_])
                )
                : "";
    }

    function _mintToken(address to, uint256 mintTokenId_, string memory tokenURI_) internal {
        _mint(to, mintTokenId_);

        _tokenURIs[mintTokenId_] = tokenURI_;
        existingTokenURIs[tokenURI_] = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721EnumerableUpgradeable) {
        require(_localAdmins[msg.sender], "permission denied");
        if (batchSize > 1) {
            revert("ERC721EnumerableUpgradeable: consecutive transfers not supported");
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenFactory.baseTokenContractsURI();
    }

    function setNewAdmin(address admin) external onlyAdmin {
        _localAdmins[admin] = true;
    }

    function deleteAdmin(address admin) external onlyAdmin {
        delete _localAdmins[admin];
    }

    function transferToken(address from, address to, uint256 tokenId) external {
        _transfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}
