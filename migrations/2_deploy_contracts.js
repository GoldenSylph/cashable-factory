const MockToken = artifacts.require('MockToken');

// const CashMachine = artifacts.require('CashMachine');
// const CashableUniswapAaveStrategy = artifacts.require('CashableUniswapAaveStrategy');
// const CashMachineFactory = artifacts.require('CashMachineFactory');
// const CashLib = artifacts.require('CashLib');

const usd = (n) => web3.utils.toWei(n, 'Mwei');
const ether = (n) => web3.utils.toWei(n, 'ether');

module.exports = function (deployer, network, accounts) {
  deployer.then(async () => {
    if (network === 'test' || network === 'soliditycoverage') {
      console.error('Test network. No migrations needed.');
    } else if (network.startsWith('kovan')) {

      // const mainToken = '0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD';
      // const mainAToken = '0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8';
      // const router = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
      // const lendingPool = '0x5c94e75316CAD5f5e0eF2E8A460Bd4aBAd6222Ee';
      //
      // const machine = await deployer.deploy(CashMachine);
      // const strategy = await deployer.deploy(CashableUniswapAaveStrategy);
      // const factory = await deployer.deploy(CashMachineFactory, machine.address, strategy.address);
      //
      // await strategy.configure(
      //   mainToken,
      //   mainAToken,
      //   router,
      //   lendingPool,
      //   factory.address
      // );

    } else {
      console.error(`Unsupported network: ${network}`);
    }
  });
};
