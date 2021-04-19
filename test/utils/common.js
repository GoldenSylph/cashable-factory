const { BN, ether, expectRevert } = require('@openzeppelin/test-helpers');

const MockToken = artifacts.require("MockToken");

const getMockTokenPrepared = async (mintTo, mockedAmount, totalSupply, from) => {
  const mockToken = await MockToken.new('Mock Token', 'MT', totalSupply, {from: from});
  if (mintTo !== from) {
    await mockToken.approve(mintTo, mockedAmount, {from});
    await mockToken.transfer(mintTo, mockedAmount, {from});
  }
  return mockToken;
};

const processEventArgs = async (result, eventName, processArgs) => {
  if (result == null) {
    throw new Error(`Result of tx is: ${result}`);
  }
  const filteredLogs = result.logs.filter(l => l.event === eventName);
  const eventArgs = filteredLogs[0].args;
  await processArgs(eventArgs);
};

const checkSetter = async (
  setterMethodName,
  getterName,
  newValue,
  validSender,
  nonValidSender,
  contractInstance,
  revertMessage
) => {
  await contractInstance[setterMethodName](newValue, {from: validSender});
  expect(await contractInstance[getterName]()).to.be.equal(newValue);
  await expectRevert(contractInstance[setterMethodName](newValue, {from: nonValidSender}), revertMessage);
};

module.exports = {
  DAY: 86400,
  HOUR: 3600,
  ZERO: new BN('0'),
  ONE: new BN('1'),
  getMockTokenPrepared,
  processEventArgs,
  checkSetter
};
