const { expectEvent, time, expectRevert, BN, ether, constants } = require('@openzeppelin/test-helpers')
const { ZERO_ADDRESS } = constants
const { expect } = require('chai')
const { toWei, fromWei } = require('web3-utils')
const ZERO = new BN('0');
require('chai').should();

const Bridge = artifacts.require('Bridge');
const WrapperBridgedStandardERC20 = artifacts.require('WrapperBridgedStandardERC20');
const IWrapperBridgedStandardERC20 = artifacts.require('IWrapperBridgedStandardERC20');
const IERC20 = artifacts.require('IERC20');

contract('Bridge', async (accounts) => {

  const owner = accounts[0];
  const alice = accounts[1];
  const bob = accounts[2];
  const feeWallet = accounts[3];

  let wrapperBridgedStandardERC20;
  let bridge2;

  beforeEach(async () => {
    wrapperBridgedStandardERC20 = await WrapperBridgedStandardERC20.new({from: owner});
    bridge2 = await Bridge.new(wrapperBridgedStandardERC20.address, feeWallet, owner, 5, 8, "WrappedICP", "WICP", {from: owner});
    await wrapperBridgedStandardERC20.configure(
        bridge2.address,
        "WICP On End",
        "LOE",
        8
    );
  });

  describe('non ERC20 standard functionality in WrapperBridgedStandardERC20', () => {

    it('should get name and symbol', async () => {
      expect(await wrapperBridgedStandardERC20.name()).to.be.equal("WICP On End");
      expect(await wrapperBridgedStandardERC20.symbol()).to.be.equal("LOE");
      const decimals = new BN('8');
      expect(await wrapperBridgedStandardERC20.decimals()).to.be.bignumber.equal(decimals);

      const tokenWICP = await IWrapperBridgedStandardERC20.at(await bridge2.iWrapperBridgedStandardERC20());
      expect(await tokenWICP.name()).to.be.equal("WICP On End");
      expect(await tokenWICP.symbol()).to.be.equal("LOE");
    });

    it('should burn if transfer to zero', async () => {
      const tokensToBridge = new BN('10');
      await bridge2.performBridgingToEnd(alice, tokensToBridge, "", "", 8);
      const tokenAtEnd = await IWrapperBridgedStandardERC20.at(await bridge2.iWrapperBridgedStandardERC20());
      await tokenAtEnd.transfer(ZERO_ADDRESS, tokensToBridge, {from: alice});
      expect(await tokenAtEnd.burnt()).to.be.bignumber.equal(tokensToBridge);
    });

    it('should transfer safely if recipient is not zero address', async () => {
      const tokensToBridge = new BN('10');
      await bridge2.performBridgingToEnd(alice, tokensToBridge, "", "", 8);
      const tokenWICP = await IWrapperBridgedStandardERC20.at(await bridge2.iWrapperBridgedStandardERC20());
      await tokenWICP.approve(bob, tokensToBridge, {from: alice});
      await tokenWICP.transfer(bob, tokensToBridge, {from: alice});
      expect(await tokenWICP.balanceOf(bob)).to.be.bignumber.equal(tokensToBridge);
    });
  });

  it('should set new admin', async () => {
    await bridge2.setAdmin(bob, {from: owner});
    const adminRole = "0x00";
    expect(await bridge2.hasRole(adminRole, bob)).to.be.true;
  });

  it('should request bridging to start', async () => {
    const tokensToBridge = new BN('1000');
    const feeAmount = new BN('5');
    const tokenWICP = await IWrapperBridgedStandardERC20.at(await bridge2.iWrapperBridgedStandardERC20());
    await bridge2.performBridgingToEnd(alice, tokensToBridge, "", "", 8);
    await tokenWICP.approve(bridge2.address, tokensToBridge, { from: alice });
    const receipt = await bridge2.requestBridgingToStart(tokensToBridge, bob, { from: alice });
    expectEvent(receipt, "RequestBridgingToStart", {
      _token: tokenWICP.address,
      _from: alice,
      _amount: tokensToBridge.sub(feeAmount)
    });
    expect(await tokenWICP.balanceOf(alice)).to.be.bignumber.equal(ZERO);
    expect(await tokenWICP.balanceOf(feeWallet)).to.be.bignumber.equal(feeAmount);
  });

  it('should not mint or burn called not by bridge', async () => {
    const tokenWICP = await IWrapperBridgedStandardERC20.at(await bridge2.iWrapperBridgedStandardERC20());
    await expectRevert(tokenWICP.mint(ZERO_ADDRESS, ZERO), "onlyBridge");
    await expectRevert(tokenWICP.burn(ZERO_ADDRESS, ZERO), "onlyBridge");
  });

  it('should revert if perform bridging called not by message bot', async () => {
    await expectRevert(bridge2.performBridgingToEnd(ZERO_ADDRESS, ZERO, "", "", 8, { from: alice }), "onlyMessengerBot");
  });
});

