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

    await tokenFactory.__TokenFactory_init([OWNER, ADMIN1, ADMIN2], baseTokenContractsURI);

    const _tokenContractImpl = await TokenContract.new();

    await tokenFactory.setNewImplementation(_tokenContractImpl.address);

    assert.equal(await tokenFactory.getTokenContractsImpl(), _tokenContractImpl.address);

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("creation", () => {
    it("should get exception if try to call init function several times", async () => {
      const reason = "Initializable: contract is already initialized";

      await truffleAssert.reverts(tokenFactory.__TokenFactory_init([ADMIN1, ADMIN2], baseTokenContractsURI), "");
    });
  });

  describe("TokenFactory upgradability", () => {
    it("should correctly upgrade pool to new impl", async () => {
      const _newTokenFactoryImpl = await TokenFactory.new();

      await tokenFactory.upgradeTo(_newTokenFactoryImpl.address);

      assert.equal(
        await (await PublicERC1967Proxy.at(tokenFactory.address)).implementation(),
        _newTokenFactoryImpl.address
      );
    });

    it("should get exception if nonowner try to upgrade", async () => {
      const _newTokenFactoryImpl = await TokenFactory.new();
      const reason = "Ownable: caller is not the owner";

      await truffleAssert.reverts(tokenFactory.upgradeTo(_newTokenFactoryImpl.address, { from: USER1 }), reason);
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

    it("should get exception if nonowner try to call this function", async () => {
      const _newTokenContractImpl = await TokenContract.new();
      const reason = "Ownable: caller is not the owner";

      await truffleAssert.reverts(
        tokenFactory.setNewImplementation(_newTokenContractImpl.address, { from: USER1 }),
        reason
      );
    });
  });

  describe("updateAdmins", () => {
    let adminsToAdd;

    beforeEach("setup", async () => {
      adminsToAdd = [await accounts(7), await accounts(8), await accounts(9)];
    });

    it("should correctly add new tokens", async () => {
      let expectedArr = [OWNER, ADMIN1, ADMIN2].concat(adminsToAdd);

      const tx = await tokenFactory.updateAdmins(adminsToAdd, true);

      assert.deepEqual(await tokenFactory.getAdmins(), expectedArr);

      assert.equal(tx.receipt.logs[0].event, "AdminsUpdated");
      assert.deepEqual(tx.receipt.logs[0].args.adminsToUpdate, adminsToAdd);
      assert.equal(tx.receipt.logs[0].args.isAdding, true);
    });

    it("should correctly remove tokens", async () => {
      await tokenFactory.updateAdmins(adminsToAdd, true);

      let expectedArr = [OWNER, ADMIN1, ADMIN2].concat(adminsToAdd[2]);

      const tx = await tokenFactory.updateAdmins(adminsToAdd.slice(0, 2), false);

      assert.deepEqual(await tokenFactory.getAdmins(), expectedArr);

      assert.equal(tx.receipt.logs[0].event, "AdminsUpdated");
      assert.deepEqual(tx.receipt.logs[0].args.adminsToUpdate, adminsToAdd.slice(0, 2));
      assert.equal(tx.receipt.logs[0].args.isAdding, false);
    });

    it("should get exception if pass zero address", async () => {
      const reason = "PoolFactory: Bad address.";

      await truffleAssert.reverts(tokenFactory.updateAdmins(adminsToAdd.concat(ZERO_ADDR), true), reason);
    });

    it("should get exception if non admin try to call this function", async () => {
      const reason = "Ownable: caller is not the owner";

      await truffleAssert.reverts(tokenFactory.updateAdmins(adminsToAdd, true, { from: USER1 }), reason);
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

  describe("getBaseTokenContractsInfo", () => {
    it("should return correct base token contracts info", async () => {
      await deployNewTokenContract({});

      let tokenContractId = "1";

      await deployNewTokenContract({ tokenContractId_: tokenContractId });

      tokenContractId = "2";

      await deployNewTokenContract({ tokenContractId_: tokenContractId });

      const tokenContractsArr = await tokenFactory.getTokenContractsPart(0, 10);

      const result = await tokenFactory.getBaseTokenContractsInfo(tokenContractsArr);

      for (let i = 0; i < tokenContractsArr.length; i++) {
        assert.equal(result[i].tokenContractAddr, tokenContractsArr[i]);
      }
    });
  });
});
