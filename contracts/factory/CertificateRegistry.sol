// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@dlsl/dev-modules/contracts-registry/pools/AbstractPoolContractsRegistry.sol";

import "../interfaces/factory/ICertificateRegistry.sol";

/**
 * @notice The PriceFeedRegistry contract that stores price feed beacon proxies.
 */
contract CertificateRegistry is ICertificateRegistry, AbstractPoolContractsRegistry {
    string public constant CREATE_PERMISSION = "CREATE";

    string public constant CERTIFICATE_REGISTRY_RESOURCE = "CERTIFICATE_REGISTRY_RESOURCE";

    string public constant CERTIFICATE_FACTORY_DEP = "CERTIFICATE_FACTORY";

    string public constant CERTIFICATE_NAME = "CERTIFICATE";

    address internal _certificateFactory;

    mapping(address => address) public override certificateTokensToPools;

    modifier onlyCertificateFactory() {
        require(_certificateFactory == msg.sender, "CertificateRegistry: caller is not a factory");
        _;
    }

    /**
     * @notice The initializer function
     * @param names_ the initial pool names
     * @param implementations_ the initial pool implementations
     */
    function __CertificateRegistry_init(
        string[] calldata names_,
        address[] calldata implementations_
    ) external initializer {
        _setNewImplementations(names_, implementations_);
    }

    /**
     * @notice The function to set dependencies
     * @dev Access: the injector address
     * @param registryAddress_ the ContractsRegistry address
     * @param data_ the empty data
     */
    function setDependencies(address registryAddress_, bytes calldata data_) public override {
        super.setDependencies(registryAddress_, data_);

        _certificateFactory = registry_.getContract(CERTIFICATE_FACTORY_DEP);
    }

    /**
     * @inheritdoc IPriceFeedRegistry
     */
    function setNewImplementations(
        string[] calldata names_,
        address[] calldata newImplementations_
    ) external override onlyCreatePermission {
        _setNewImplementations(names_, newImplementations_);
    }

    /**
     * @inheritdoc IPriceFeedRegistry
     */
    function injectDependenciesToExistingPools(
        string calldata name_,
        uint256 offset_,
        uint256 limit_
    ) external override onlyCreatePermission {
        _injectDependenciesToExistingPools(name_, offset_, limit_);
    }

    /**
     * @inheritdoc IPriceFeedRegistry
     */
    function injectDependenciesToExistingPoolsWithData(
        string calldata name_,
        bytes calldata data_,
        uint256 offset_,
        uint256 limit_
    ) external override onlyCreatePermission {
        _injectDependenciesToExistingPoolsWithData(name_, data_, offset_, limit_);
    }

    /**
     * @notice The function to add the proxy pool
     * @dev Access: PriceFeedFactory
     * @param name_ the type of the pool
     * @param poolAddress_ the beacon proxy address of the pool
     */
    function addProxyPool(
        string calldata name_,
        address poolAddress_
    ) external onlyCertificateFactory {
        _addProxyPool(name_, poolAddress_);
    }

    /**
     * @inheritdoc IPriceFeedRegistry
     */
    function addCertificateTokenByPool(
        address poolAddress_,
        address certificateTokenAddr_
    ) external override onlyCertificateFactory {
        certificateTokensToPools[certificateTokenAddr_] = poolAddress_;
    }

    /**
     * @inheritdoc IPriceFeedRegistry
     */
    function getCertificatesByTokens(
        address[] memory certificateTokensArr_
    ) external view override returns (address[] memory certificatesArr_) {
        certificatesArr_ = new address[](certificateTokensArr_.length);

        for (uint256 i = 0; i < certificateTokensArr_.length; ++i) {
            certificatesArr_[i] = certificateTokensToPools[certificateTokensArr_[i]];
        }
    }

    /**
     * @inheritdoc IPriceFeedRegistry
     */
    function getCertificatesInfo(
        uint256 offset_,
        uint256 limit_
    ) external view override returns (CertificateInfo[] memory certificateTokensArr_) {
        address[] memory certificateArr_ = listPools(CERTIFICATE_NAME, offset_, limit_);

        certificateTokensArr_ = new CertificateInfo[](certificateArr_.length);

        for (uint256 i = 0; i < certificateArr_.length; ++i) {
            certificateTokensArr_[i] = CertificateInfo(
                certificateArr_[i],
                ICertificate(certificateArr_[i]).certificateTokenAddr()
            );
        }
    }

    /**
     * @notice The internal function to optimize the bytecode for the permission check
     */
    function _requireCreatePermission() internal view {
        require(
            _masterAccess.hasPermission(
                msg.sender,
                CERTIFICATE_REGISTRY_RESOURCE,
                CREATE_PERMISSION
            ),
            "CertificateRegistry: access denied"
        );
    }
}
