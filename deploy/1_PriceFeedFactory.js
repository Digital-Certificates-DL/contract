const { getConfigJson } = require("./config/config-getter");
const { CERTIFICATE_FACTORY_DEP } = require("./utils/constants");

const Registry = artifacts.require("MasterContractsRegistry");
const CertificateFactory = artifacts.require("CertificateFactory");

module.exports = async (deployer, logger) => {
  const config = await getConfigJson();

  if (config.addresses == undefined || config.addresses.MasterContractsRegistry == undefined) {
    throw new Error(`invalid config fetched`);
  }

  deployer.masterContractsRegistry = config.addresses.MasterContractsRegistry;

  const registry = await Registry.at(deployer.masterContractsRegistry);
  d;
  const certificateFactory = await deployer.deploy(CertificateFactory);

  logger.logTransaction(
    await registry.addProxyContract(CERTIFICATE_FACTORY_DEP, certificateFactory.address),
    "Deploy CertificateFactory"
  );
};
