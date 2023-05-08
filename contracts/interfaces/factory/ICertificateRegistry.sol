// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICertificateRegistry {
    struct CertificateInfo {
        address certificateAddr;
        address certificateTokenAddr;
    }

    /**
     * @notice The function is needed to set and update contract implementations by a specific name
     * @dev Access: CREATE permission
     * @param names_ the array of names for which new implementations will be set
     * @param newImplementations_ the array of the new implementations
     */
    function setNewImplementations(
        string[] calldata names_,
        address[] calldata newImplementations_
    ) external;

    /**
     * @notice The function to update dependencies in all contracts by a specific name
     * @dev Access: CREATE permission
     * @param name_ the name by which the dependencies in all contracts will be updated
     * @param offset_ the offset for pagination
     * @param limit_ the maximum number of elements for
     */
    function injectDependenciesToExistingPools(
        string calldata name_,
        uint256 offset_,
        uint256 limit_
    ) external;

    /**
     * @notice The function to update dependencies in all contracts by a specific name with data
     * @dev Access: CREATE permission
     * @param name_ the name by which the dependencies in all contracts will be updated
     * @param data_ the data to be passed into the dependant function
     * @param offset_ the offset for pagination
     * @param limit_ the maximum number of elements for
     */
    function injectDependenciesToExistingPoolsWithData(
        string calldata name_,
        bytes calldata data_,
        uint256 offset_,
        uint256 limit_
    ) external;

    /**
     * @notice The function to add information about the price feed token of a specific price feed
     * @dev Access: PriceFeedFactory
     * @param poolAddress_ the beacon proxy address of the pool
     * @param priceFeedTokenAddr_ the address of the price feed token
     */
    function addCertificateTokenByPool(
        address poolAddress_,
        address certificateTokenAddr_
    ) external;

    /**
     * @notice The function to get the price feed address from a specific token address
     * @param priceFeedTokenAddr_ the address of the token for which you want to get the price feed address
     * @return the address of the price feed beacon proxy
     */
    function certificateToPools(address certificateTokenAddr_) external view returns (address);

    /**
     * @notice The function to get an array of price feed addresses for an array of token addresses
     * @param priceFeedTokensArr_ the array of addresses of the tokens for which you want to get information
     * @return priceFeedsArr_ the array of price feeds
     */
    function getCertificateByTokens(
        address[] memory certificateTokensArr_
    ) external view returns (address[] memory certificateArr_);

    /**
     * @notice The function for getting paginated information about price feeds
     * @param offset_ the starting index in the price feeds array
     * @param limit_ the number of price feeds
     * @return priceFeedInfoArr_ the array with PriceFeedInfo structures
     */
    function getCertificatesInfo(
        uint256 offset_,
        uint256 limit_
    ) external view returns (CertificateInfo[] memory certificateInfoArr_);
}
