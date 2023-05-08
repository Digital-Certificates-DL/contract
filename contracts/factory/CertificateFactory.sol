// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@dlsl/dev-modules/contracts-registry/pools/pool-factory/AbstractPoolFactory.sol";

import "../interfaces/factory/ICertificateFactory.sol";

import "../certificate/Certificate.sol";
import "./CertificateRegistry.sol";

/**
 * @notice The CertificateFactory contract that deploys beacon proxies that point to price feed implementations.
 * Works together with CertificateRegistry.
 */
contract CertificateFactory is ICertificateFactory, AbstractPoolFactory {
    string public constant CREATE_PERMISSION = "CREATE";

    string public constant PRICE_FEED_FACTORY_RESOURCE = "PRICE_FEED_FACTORY_RESOURCE";

    string public constant PRICE_FEED_FACTORY_DEP = "PRICE_FEED_FACTORY";
    string public constant PRICE_FEED_REGISTRY_DEP = "PRICE_FEED_REGISTRY";

    modifier onlyCreatePermission() {
        require(
            _masterAccess.hasPermission(
                msg.sender,
                PRICE_FEED_FACTORY_RESOURCE,
                CREATE_PERMISSION
            ),
            "CertificateFactory: access denied"
        );
        _;
    }

    /**
     * @notice The function to set dependencies
     * @dev Access: the injector address
     * @param registryAddress_ the ContractsRegistry address
     * @param data_ the empty data
     */
    function setDependencies(address registryAddress_, bytes calldata data_) public override {
        super.setDependencies(registryAddress_, data_);

        _certificateRegistry = CertificateRegistry(registry_.getContract(PRICE_FEED_REGISTRY_DEP));
    }

    /**
     * @inheritdoc ICertificateFactory
     */
    function deployCertificate(
        ICertificate.CertificateInitParams calldata initParams_
    ) external override onlyCreatePermission {
        CertificateRegistry certificateRegistry_ = _certificateRegistry;

        string memory certificateType_ = certificateRegistry_.PRICE_FEED_NAME();
        address certificateProxy_ = _deploy(address(certificateRegistry_), certificateType_);

        Certificate(certificateProxy_).__Certificate_init(initParams_);

        _register(address(certificateRegistry_), certificateType_, certificateProxy_);
        _injectDependencies(address(certificateRegistry_), certificateProxy_);

        certificateRegistry_.addCertificateTokenByPool(
            certificateProxy_,
            initParams_.certificateTokenAddr
        );

        emit CertificateDeployed(certificateProxy_);
    }
}
