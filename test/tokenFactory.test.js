const { accounts } = require("../scripts/utils/utils");
const { ZERO_ADDR } = require("../scripts/utils/constants");

const truffleAssert = require("truffle-assertions");
const Reverter = require("./helpers/reverter");
const { assert } = require("chai");

const TokenFactory = artifacts.require("TokenFactory");
const TokenContract = artifacts.require("TokenContract");

const PublicERC1967Proxy = artifacts.require("PublicERC1967Proxy");

TokenFactory.numberFormat = "BigNumber";

describe("TokenFactory", () => {
  const reverter = new Reverter();

  const baseTokenContractsURI = "base uri/";

  const defaultTokenContractId = "0";
  const defaultTokenName = "tokenName";
  const defaultTokenSymbol = "tokenSymbol";

  let OWNER;
  let USER1;
  let ADMIN1;
  let ADMIN2;

  let tokenFactory;
  let tokenFactoryImpl;

  async function deployNewTokenContract({
    tokenContractId_ = defaultTokenContractId,
    tokenName_ = defaultTokenName,
    tokenSymbol_ = defaultTokenSymbol,
  }) {
    return await tokenFactory.deployTokenContract(
      [tokenContractId_, tokenName_, tokenSymbol_],

      { from: USER1 }
    );
  }

  before("setup", async () => {
    OWNER = await accounts(0);
    USER1 = await accounts(1);
    ADMIN1 = await accounts(2);
    ADMIN2 = await accounts(3);

    tokenFactoryImpl = await TokenFactory.new();
    const _tokenFactoryProxy = await PublicERC1967Proxy.new(tokenFactoryImpl.address, "0x");

    tokenFactory = await TokenFactory.at(_tokenFactoryProxy.address);

    await tokenFactory.__TokenFactory_init(baseTokenContractsURI);

    const _tokenContractImpl = await TokenContract.new();

    await tokenFactory.setNewImplementation(_tokenContractImpl.address);

    assert.equal(await tokenFactory.getTokenContractsImpl(), _tokenContractImpl.address);

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("creation", () => {
    it("should get exception if try to call init function several times", async () => {
      const reason = "Initializable: contract is already initialized";

      await truffleAssert.reverts(tokenFactory.__TokenFactory_init(baseTokenContractsURI), reason);
    });
  });

  describe("setBaseTokenContractsURI", () => {
    it("should correctly update base token contracts URI", async () => {
      const newBaseTokenContractsURI = "new base URI/";

      const tx = await tokenFactory.setBaseTokenContractsURI(newBaseTokenContractsURI);

      assert.equal(await tokenFactory.baseTokenContractsURI(), newBaseTokenContractsURI);

      assert.equal(tx.receipt.logs[0].event, "BaseTokenContractsURIUpdated");
      assert.equal(tx.receipt.logs[0].args.newBaseTokenContractsURI, newBaseTokenContractsURI);
    });

    it("should get exception if nonowner try to call this function", async () => {
      const reason = "Ownable: caller is not the owner";

      await truffleAssert.reverts(tokenFactory.setBaseTokenContractsURI("", { from: USER1 }), reason);
    });
  });

  describe("setNewImplementation", () => {
    it("should correctly set new implementation of the TokenContract", async () => {
      const _newTokenContractImpl = await TokenContract.new();

      await tokenFactory.setNewImplementation(_newTokenContractImpl.address);
      assert.equal(await tokenFactory.getTokenContractsImpl(), _newTokenContractImpl.address);

      await tokenFactory.setNewImplementation(_newTokenContractImpl.address);
      assert.equal(await tokenFactory.getTokenContractsImpl(), _newTokenContractImpl.address);
    });
  });

  describe("deployTokenContract", () => {
    it("should get exception if try to deploy tokenContaract with already existing tokenContractId", async () => {
      const reason = "TokenFactory: TokenContract with such id already exists.";

      await tokenFactory.deployTokenContract([defaultTokenContractId, defaultTokenName, defaultTokenSymbol], {
        from: USER1,
      });

      await truffleAssert.reverts(
        tokenFactory.deployTokenContract([defaultTokenContractId, defaultTokenName, defaultTokenSymbol], {
          from: USER1,
        }),
        reason
      );
    });
  });
});
