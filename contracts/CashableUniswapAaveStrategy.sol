// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


import "./lib/CashLib.sol";
import "./interfaces/ICash.sol";
import "./interfaces/ICashMachine.sol";
import "./interfaces/third_party/aave/ILendingPool.sol";
import "./interfaces/ICashableStrategy.sol";

contract CashableUniswapAaveStrategy is Ownable, Initializable, AccessControlEnumerable, ICashableStrategy {

    using SafeERC20 for IERC20;
    using Address for address payable;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint16 public constant AAVE_REFERRAL_CODE = 96;
    bytes32 public constant CASH_MACHINE_CLONE_ROLE = keccak256("CASH_MACHINE_CLONE_ROLE");
    uint256 public constant MULTIPLIER = 10 ** 18;

    // cash machine => token
    mapping(address => address) public tokens;

    // cash machine => volume
    mapping(address => uint256) public volumes;

    // creator => share
    mapping(address => uint256) public shares;
    EnumerableSet.AddressSet private _creators;

    uint256 public totalAmountOfMainTokens;
    uint256 public rateNominator;
    uint256 public rateDenominator;

    IERC20 public mainToken;
    IERC20 public mainAToken;
    ICash public cashToken;
    IUniswapV2Router02 public uniswapRouter;
    ILendingPool public aaveLendingPool;
    address public cashMachineFactory;

    event Harvest(uint256 indexed _revenue);
    event Register(
        address indexed _cashMachine,
        uint256 indexed _sumOfNominals,
        uint256 indexed _sumOfNominalsInMainTokens
    );
    event Unregister(
        address indexed _cashMachine,
        address indexed _creator
    );
    event Withdraw(
        address indexed _cashMachine,
        uint256 indexed _nominal,
        uint256 indexed _nominalInMainTokens
    );

    modifier onlyCashMachineClone {
        require(hasRole(CASH_MACHINE_CLONE_ROLE, _msgSender()), "!senderCashMachine");
        _;
    }

    modifier onlyCashMachineFactory {
        require(_msgSender() == cashMachineFactory, "!senderCashMachineFactory");
        _;
    }

    modifier onlyOwnerOrSelf {
        address sender = _msgSender();
        require(sender == owner() || sender == address(this), "!owner|self");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    function configure(
      uint256 _rateNominator,
      uint256 _rateDenominator,
      address _mainToken,
      address _mainAToken,
      address _uniswapRouter,
      address _aaveLendingPool,
      address _cashMachineFactory,
      address _cashToken
    ) external initializer {
        require(_rateNominator <= _rateDenominator, "gtOne");
        mainToken = IERC20(_mainToken);
        mainAToken = IERC20(_mainAToken);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        aaveLendingPool = ILendingPool(_aaveLendingPool);
        cashMachineFactory = _cashMachineFactory;
        cashToken = ICash(_cashToken);
    }

    function _getAmountOut(address _from, address _to, uint256 _amount) internal view returns(uint256, address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        uint256[] memory _amountsOut = uniswapRouter.getAmountsOut(_amount, path);
        return (_amountsOut[1], path);
    }

    function _convertUniswap(address _tokenIn, address _tokenOut, uint256 _amount) internal returns(uint256 amountOut) {
      if (_tokenIn != _tokenOut) {
            require(IERC20(_tokenIn).approve(address(uniswapRouter), _amount), '!uniswapApprove');
            address[] memory path;
            (amountOut, path) = _getAmountOut(_tokenIn, _tokenOut, _amount);
            if (_tokenIn != CashLib.ETH && _tokenOut == CashLib.ETH) {
                uniswapRouter.swapExactTokensForETH(_amount, amountOut, path, msg.sender, block.timestamp);
            } else if (_tokenIn == CashLib.ETH && _tokenOut != CashLib.ETH) {
                uniswapRouter.swapExactETHForTokens{value: _amount}(amountOut, path, msg.sender, block.timestamp);
            } else {
                uniswapRouter.swapExactTokensForTokens(_amount, amountOut, path, msg.sender, block.timestamp);
            }
        } else {
            amountOut = _amount;
        }
    }

    function register(address _cashMachine, address _creator, address _token, uint256 _amount)
        external
        override
        onlyCashMachineFactory
    {
        grantRole(CASH_MACHINE_CLONE_ROLE, _cashMachine);
        tokens[_cashMachine] = _token;
        volumes[_cashMachine] = _amount;
        address mainTokenAddress = address(mainToken);
        uint256 amountInMainTokens = _convertUniswap(_token, mainTokenAddress, _amount);
        mainToken.approve(address(aaveLendingPool), amountInMainTokens);
        aaveLendingPool.deposit(mainTokenAddress, amountInMainTokens, address(this), AAVE_REFERRAL_CODE);
        totalAmountOfMainTokens = totalAmountOfMainTokens.add(amountInMainTokens);

        shares[_creator] = (amountInMainTokens / totalAmountOfMainTokens) * MULTIPLIER;
        _creators.add(_creator);

        emit Register(_cashMachine, _amount, amountInMainTokens);
    }

    function harvest() override public onlyOwnerOrSelf {
        uint256 aMainTokenBalance = mainAToken.balanceOf(address(this));
        if (aMainTokenBalance > totalAmountOfMainTokens) {
            uint256 revenue = aMainTokenBalance.sub(totalAmountOfMainTokens);
            address _owner = owner();
            mainAToken.safeTransfer(_owner, revenue);

            for (uint256 i = 0; i < _creators.length(); i++) {
                address _creator = _creators.at(i);
                cashToken.mint(_creator, revenue * (shares[_creator] / MULTIPLIER) / (rateNominator / rateDenominator));
            }

            emit Harvest(revenue);
        }
    }


    function withdraw(uint256 _amount)
        external
        override
        onlyCashMachineClone
    {
        address sender = _msgSender();
        uint256 volume = volumes[sender];
        address token = tokens[sender];
        address mainTokenAddress = address(mainToken);

        (uint256 amountInMainTokens,) = _getAmountOut(token, mainTokenAddress, _amount);

        mainAToken.approve(address(aaveLendingPool), amountInMainTokens);
        aaveLendingPool.withdraw(mainTokenAddress, amountInMainTokens, address(this));

        uint256 amountInTokens = _convertUniswap(mainTokenAddress, token, amountInMainTokens);

        if (token != CashLib.ETH) {
            IERC20(token).safeTransfer(sender, amountInTokens);
        } else {
            payable(sender).sendValue(amountInTokens);
        }

        (,totalAmountOfMainTokens) = totalAmountOfMainTokens.trySub(amountInMainTokens);

        (,volumes[sender]) = volume.trySub(amountInTokens);
        if (volumes[sender] == 0) {
            address _creator = ICashMachine(sender).creator();
            revokeRole(CASH_MACHINE_CLONE_ROLE, sender);
            delete tokens[sender];
            delete shares[_creator];
            _creators.remove(_creator);
            emit Unregister(sender, _creator);
        }
        emit Withdraw(sender, amountInTokens, amountInMainTokens);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns(bool) {
        return super.supportsInterface(interfaceId)
          || interfaceId == CashLib.CASHABLE_AAVE_STRATEGY_ERC165;
    }

    fallback() external {
        revert("NoFallback");
    }

    receive() payable external {}

}
