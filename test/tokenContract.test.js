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

  const defaultTokenURI = "some uri";
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
    console.log(tokenContractId_, tokenName_, tokenSymbol_);
    // console.log(tokenFactorys)
    return await tokenFactory.deployTokenContract([tokenContractId_, tokenName_, tokenSymbol_], { from: OWNER });
  }

  before("setup", async () => {
    OWNER = await accounts(0);
    USER1 = await accounts(1);
    ADMIN1 = await accounts(2);
    ADMIN2 = await accounts(3);

    console.log("OWNER ", OWNER);
    console.log("USER1 ", USER1);
    console.log("ADMIN1 ", ADMIN1);
    console.log("ADMIN2 ", ADMIN2);

    tokenFactoryImpl = await TokenFactory.new();
    const _tokenFactoryProxy = await PublicERC1967Proxy.new(tokenFactoryImpl.address, "0x");

    tokenFactory = await TokenFactory.at(_tokenFactoryProxy.address);

    await tokenFactory.__TokenFactory_init([OWNER, ADMIN1, ADMIN2], baseTokenContractsURI);

    const _tokenContractImpl = await TokenContract.new();

    await tokenFactory.setNewImplementation(_tokenContractImpl.address);

    assert.equal(await tokenFactory.getTokenContractsImpl(), _tokenContractImpl.address);

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("creation", () => {
    it("should mint token", async () => {
      await deployNewTokenContract({});

      const tokenID = await tokenFactory.tokenContractByIndex(defaultTokenContractId);
      console.log("tokenID ", tokenID);
      tokenContract = await TokenContract.at(tokenID);

      console.log("address mint ", OWNER);
      await tokenContract.mintToken(USER1, "test link");
    });
  });

  // describe("creation", () => {
  //   it("should mint token", async () => {
  //
  //     await deployNewTokenContract({ });
  //
  //     tokenContract = await TokenContract.at(await tokenFactory.tokenContractByIndex(defaultTokenContractId));
  //
  //
  //
  //
  //     console.log("address mint ", OWNER)
  //     await tokenContract.mintToken(USER1, "test link")
  //
  //   });
  // });
});
