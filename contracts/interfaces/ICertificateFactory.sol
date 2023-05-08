// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../price-feeds/ICertificate.sol";

/**
 * @notice The CertificateFactory contract is designed to deploy new Certificate contract instances.
 *
 * Only users with the necessary permissions can deploy new instances
 */
interface ICertificateFactory {
    /**
     * @notice This event is emitted when a new Certificate contract is deployed
     * @param certificate the address of the deployed price feed contract
     */
    event CertificateDeployed(address certificate);

    /**
     * @notice The function to deploy the price feed
     * @dev Access: CREATE permission
     * @param initParams_ the price feed initial parameters
     */
    function deployCertificate(ICertificate.CertificateInitParams calldata initParams_) external;
}
