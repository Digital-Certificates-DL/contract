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

  const baseTokenContractsURI = "ipfs://";

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
    return await tokenFactory.deployTokenContract([tokenContractId_, tokenName_, tokenSymbol_], { from: OWNER });
  }

  before("setup", async () => {
    OWNER = await accounts(0);
    USER1 = await accounts(1);
    ADMIN1 = await accounts(2);
    ADMIN2 = await accounts(3);

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

      tokenContract = await TokenContract.at(tokenID);

      await tokenContract.mintToken(USER1, "test link");
    });
  });

  describe("creation", () => {
    it("should mint token", async () => {
      await deployNewTokenContract({});

      const tokenID = await tokenFactory.tokenContractByIndex(defaultTokenContractId);

      const tokenContract = await TokenContract.at(tokenID);

      const tx = await tokenContract.mintToken(USER1, "test link");
    });
  });
  describe("safeMint", () => {
    it("should mint correctly and return correct uri", async () => {
      await deployNewTokenContract({});

      const tokenID = await tokenFactory.tokenContractByIndex(defaultTokenContractId);

      const tokenContract = await TokenContract.at(tokenID);

      assert.equal(await tokenContract.balanceOf(USER1), "0");
      await tokenContract.mintToken(USER1, "test", { from: OWNER });
      assert.equal(await tokenContract.tokenURI(0), "ipfs://test");
      assert.equal(await tokenContract.balanceOf(USER1), "1");
    });
  });
  describe("mint token: check  permission", () => {
    it("should mint token", async () => {
      await deployNewTokenContract({});

      const tokenID = await tokenFactory.tokenContractByIndex(defaultTokenContractId);
      const tokenContract = await TokenContract.at(tokenID);

      assert.equal(await tokenContract.balanceOf(USER1), "0");
      await tokenContract.mintToken(USER1, "test", { from: OWNER });
      assert.equal(await tokenContract.tokenURI(0), "ipfs://test");
      assert.equal(await tokenContract.balanceOf(USER1), "1");
    });
    it("shouldn't mint token", async () => {
      const reason = "permission denied";
      await deployNewTokenContract({});
      const tokenID = await tokenFactory.tokenContractByIndex(defaultTokenContractId);
      const tokenContract = await TokenContract.at(tokenID);
      assert.equal(await tokenContract.balanceOf(USER1), "0");
      await truffleAssert.reverts(tokenContract.mintToken(USER1, "test", { from: USER1 }), reason);
    });

    describe("transfer", () => {
      it("should transfer", async () => {
        await deployNewTokenContract({});

        const constractID = await tokenFactory.tokenContractByIndex(defaultTokenContractId);
        const tokenContract = await TokenContract.at(constractID);

        await tokenContract.mintToken(USER1, "test");

        await tokenContract.transferToken(USER1, OWNER, 0), { from: OWNER };

        assert.equal(await tokenContract.balanceOf(USER1), "0");
        assert.equal(await tokenContract.balanceOf(OWNER), "1");
        await tokenContract.burn(0);
      });
      it("shouldn't transfer", async () => {
        const reason = "permission denied";
        await deployNewTokenContract({});

        const constractID = await tokenFactory.tokenContractByIndex(defaultTokenContractId);
        const tokenContract = await TokenContract.at(constractID);

        await tokenContract.mintToken(USER1, "test");

        await truffleAssert.reverts(tokenContract.transferToken(USER1, OWNER, 0, { from: ADMIN2 }), reason);

        await tokenContract.burn(0);
      });
    });
  });
});
