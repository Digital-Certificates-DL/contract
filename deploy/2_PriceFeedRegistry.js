const { CERTIFICATE_REGISTRY_DEP } = require("./utils/constants");

const CertificateRegistry = artifacts.require("CertificateRegistry");
const Certificate = artifacts.require("Certificate");

module.exports = async (deployer, logger) => {
  const registry = await Registry.at(deployer.masterContractsRegistry);

  const certificateRegistry = await deployer.deploy(CertificateRegistry);
  await deployer.deploy(Certificate);

  logger.logTransaction(
    await registry.addProxyContract(CERTIFICATE_REGISTRY_DEP, certificateRegistry.address),
    "Deploy CertificateRegistry"
  );
};
