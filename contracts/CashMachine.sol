// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/_token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/_token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./lib/CashLib.sol";
import "./utils/FundsEvacuator.sol";
import "./interfaces/ICashMachine.sol";
import "./interfaces/ICashableStrategy.sol";


contract CashMachine is Initializable, FundsEvacuator, ERC165, ICashMachine, Context  {

  using SafeERC20 for IERC20;
  using Address for address payable;
  using SafeMath for uint256;
  using CashLib for CashLib.CashSet;

  address public _token;
  address payable public team;
  address public strategy;
  address public cashMachineFactory;

  address private nominalsSum;
  address private machineCreator;

  CashLib.CashSet private cashPile;

  event Operation(address indexed _token, uint256 indexed _amount, bool earnOrHarvest);

  modifier onlyCashMachineFactory {
      require(_msgSender() == cashMachineFactory, "!cashMachineFactory");
      _;
  }

  function configure(
      address _token,
      address payable _team,
      address _strategy,
      address _cashMachineFactory,
      address __machineCreator,
      uint256 __nominalsSum,
      uint256[] memory _nominals,
      address[] memory _holders,
      uint256[] memory _designs,
  ) external initializer onlyCashMachineFactory {
      require(_nominals.length == _holders.length, "!lengths");
      _token = _token;
      team = _team;
      strategy = _strategy;
      cashMachineFactory = _cashMachineFactory;
      _setEvacuator(team, false);
      _setTokenToStay(_token);
      _nominalsSum = __nominalsSum;
      _machineCreator = __machineCreator;
      for (uint256 i = 0; i < _nominals.length; i++) {
          cashPile.add(
            CashLib.Cash({
                id: i,
                holder: _holders[i],
                nominal: _nominals[i],
                design: _designs[i]
            })
          );
      }
  }

  function token() external view returns(address) {
      return _token;
  }

  function creator() external view returns(address) {
      return _machineCreator;
  }

  function nominalsSum() external view returns(uint256) {
      return _nominalsSum;
  }

  function burn(address payable _to, uint256 _id) override public {
      require(cashPile.atHolder(_id) == _msgSender(), "onlyHolder");
      uint256 nominal = cashPile.atNominal(_id);
      ICashableStrategy(strategy).withdraw(nominal);

      IERC20 tokenErc20 = IERC20(_token);
      if (_token != CashLib.ETH) {
          tokenErc20.safeTransfer(_to, nominal);
      } else {
          _to.sendValue(nominal);
      }
      require(cashPile.removeAt(_id), '!removed');

      // if some funds are stuck in here - they are sent to team address, to further return or reinvest
      if (cashPile.length() == 0) {
          if (_token != CashLib.ETH) {
              uint256 balance = tokenErc20.balanceOf(address(this));
              if (balance > 0) {
                  tokenErc20.safeTransfer(team, balance);
              }
          }
          selfdestruct(team);
      }
  }

  function burnMany(address payable _to, uint256[] _ids) override external {
      for (uint256 i = 0; i < _ids.length; i++) {
          burn(_to, _ids[i]);
      }
  }

  function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
      return interfaceId == 0x01ffc9a7
        || interfaceId == CashLib.MACHINE_ERC165;
  }

  fallback() external {
      revert("NoFallback");
  }

  receive() payable external {}

}
