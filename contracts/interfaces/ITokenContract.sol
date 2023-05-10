// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./ITokenFactory.sol";

/**
 * This is a TokenContract, which is an ERC721 token.
 * This contract allows users to buy NFT tokens for any ERC20 token and native currency, provided the admin signs off on the necessary data.
 * System admins can update the parameters, as well as pause the purchase
 * All funds for which users buy tokens can be withdrawn by the main owner of the system.
 */
interface ITokenContract {
    /*
     * @notice The structure that stores information about the minted token
     * @param tokenId the ID of the minted token
     * @param mintedTokenPrice the price to be paid by the user
     * @param tokenURI the token URI hash string
     */
    struct MintedTokenInfo {
        uint256 tokenId;
        string tokenURI;
    }

    /*
     * @notice The structure that stores TokenContract init params
     * @param tokenName the name of the collection (Uses in ERC721 and ERC712)
     * @param tokenSymbol the symbol of the collection (Uses in ERC721)
     * @param tokenFactoryAddr the address of the TokenFactory contract
     */
    struct TokenContractInitParams {
        string tokenName;
        string tokenSymbol;
        address tokenFactoryAddr;
        address admin;
    }

    /*
     * @notice This event is emitted when the TokenContract parameters are updated
     * @param newPrice the new price per token for this collection
     * @param tokenName the new token name
     * @param tokenSymbol the new token symbol
     */
    event TokenContractParamsUpdated(string tokenName, string tokenSymbol);

    /*
     * @notice This event is emitted when the user has successfully minted a new token
     * @param recipient the address of the user who received the token and who paid for it
     * @param mintedTokenInfo the MintedTokenInfo struct with information about minted token
     * @param paymentTokenAddress the address of the payment token contract
     * @param paidTokensAmount the amount of tokens paid
     * @param paymentTokenPrice the price in USD of the payment token
     * @param discount discount value applied
     */
    event SuccessfullyMinted(address indexed recipient, MintedTokenInfo mintedTokenInfo);

    /*
     * @notice The function for initializing contract variables
     * @param initParams_ the TokenContractInitParams structure with init params
     */
    function __TokenContract_init(TokenContractInitParams calldata initParams_) external;

    /*
     * @notice The function for updating token contract parameters
     * @param newPrice_ the new price per one token
     * @param newMinNFTFloorPrice_ the new minimal NFT floor price
     * @param newTokenName_ the new token name
     * @param newTokenSymbol_ the new token symbol
     */
    function updateTokenContractParams(
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) external;

    /*
     * @notice The function for updating all TokenContract parameters
     * @param newPrice_ the new price per one token
     * @param newMinNFTFloorPrice_ the new minimal NFT floor price
     * @param newVoucherTokenContract_ the address of the new voucher token contract
     * @param newVoucherTokensAmount_ the new voucher tokens amount
     * @param newTokenName_ the new token name
     * @param newTokenSymbol_ the new token symbol
     */
    function updateAllParams(string memory newTokenName_, string memory newTokenSymbol_) external;

    /*
     * @notice The function for pausing mint functionality
     */
    function pause() external;

    /*
     * @notice The function for unpausing mint functionality
     */
    function unpause() external;

    /*
     * @param tokenURI_ the tokenURI string

     */
    function mintToken(address to, string memory tokenURI_) external payable;

    /*
     * @notice The function that returns the address of the token factory
     * @return token factory address
     */
    function tokenFactory() external view returns (ITokenFactory);

    /*
     * @notice The function to check if there is a token with the passed token URI
     * @param tokenURI_ the token URI string to check
     * @return true if passed token URI exists, false otherwise
     */
    function existingTokenURIs(string memory tokenURI_) external view returns (bool);

    /*
     * @notice The function to get an array of tokenIDs owned by a particular user
     * @param userAddr_ the address of the user for whom you want to get information
     * @return tokenIDs_ the array of token IDs owned by the user
     */
    function getUserTokenIDs(address userAddr_) external view returns (uint256[] memory tokenIDs_);
}
