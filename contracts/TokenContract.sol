// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@dlsl/dev-modules/libs/decimals/DecimalsConverter.sol";
import "@dlsl/dev-modules/utils/Globals.sol";

import "./interfaces/ITokenFactory.sol";
import "./interfaces/ITokenContract.sol";
import "./interfaces/IOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract TokenContract is
    ITokenContract,
    IOwnable,
    ERC721EnumerableUpgradeable,
    EIP712Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Holder
{
    ITokenFactory public override tokenFactory;

    uint256 internal _tokenId;
    string internal _tokenName;
    string internal _tokenSymbol;

    mapping(address => bool) private localAdmins;
    mapping(string => bool) public override existingTokenURIs;
    mapping(uint256 => string) internal _tokenURIs;

    modifier onlyAdmin() {
        require(
            tokenFactory.isAdmin(msg.sender),
            "TokenContract: Only admin can call this function."
        );
        _;
    }

    modifier onlyOwner() {
        require(localAdmins[msg.sender], "permission denied");
        _;
    }

    function __TokenContract_init(
        TokenContractInitParams calldata initParams_
    ) external override initializer {
        __ERC721_init(initParams_.tokenName, initParams_.tokenSymbol);

        tokenFactory = ITokenFactory(initParams_.tokenFactoryAddr);

        _updateTokenContractParams(initParams_.tokenName, initParams_.tokenSymbol);

        localAdmins[msg.sender] = true;
    }

    function updateTokenContractParams(
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) external override onlyAdmin {
        _updateTokenContractParams(newTokenName_, newTokenSymbol_);
    }

    function pause() external override onlyAdmin {
        _pause();
    }

    function unpause() external override onlyAdmin {
        _unpause();
    }

    function mintToken(string memory tokenURI_) external payable whenNotPaused nonReentrant {
        uint256 currentTokenId_ = _tokenId++;
        _mintToken(currentTokenId_, tokenURI_);

        emit SuccessfullyMinted(msg.sender, MintedTokenInfo(currentTokenId_, tokenURI_));
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

    function name() public view override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view override returns (string memory) {
        return _tokenSymbol;
    }

    function _updateTokenContractParams(
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) internal {
        _tokenName = newTokenName_;
        _tokenSymbol = newTokenSymbol_;

        emit TokenContractParamsUpdated(newTokenName_, newTokenSymbol_);
    }

    function _mintToken(uint256 mintTokenId_, string memory tokenURI_) internal {
        _mint(msg.sender, mintTokenId_);

        _tokenURIs[mintTokenId_] = tokenURI_;
        existingTokenURIs[tokenURI_] = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721EnumerableUpgradeable) {
        require(localAdmins[msg.sender], "permission denied");

        if (batchSize > 1) {
            revert("ERC721EnumerableUpgradeable: consecutive transfers not supported");
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenFactory.baseTokenContractsURI();
    }

    function setNewAdmin(address admin) external onlyOwner {
        localAdmins[admin] = true;
    }

    function deleteAdmin(address admin) external onlyOwner {
        delete localAdmins[admin];
    }

    function updateAllParams(
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) external {}
}
