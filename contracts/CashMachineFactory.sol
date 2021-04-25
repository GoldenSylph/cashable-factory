// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./CashMachine.sol";
import "./lib/CashLib.sol";
import "./utils/FundsEvacuator.sol";
import "./interfaces/ICashMachineFactory.sol";
import "./interfaces/ICashableStrategy.sol";


contract CashMachineFactory is Ownable, ReentrancyGuard, FundsEvacuator, ERC165, ICashMachineFactory {

    using SafeERC20 for IERC20;
    using Address for address payable;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    address public cashMachineImpl;
    address public defaultStrategy;
    IERC721 public designNft;

    event CashMachineCreated(address _cashMachineClone, address _cashMachineMain);

    constructor(address _cashMachineImpl, address _defaultStrategy, address _designNft) {
        cashMachineImpl = _cashMachineImpl;
        _setEvacuator(owner(), true);
        defaultStrategy = _defaultStrategy;
        designNft = IERC721(_designNft);
    }

    function cashMachineFactoryName() external pure returns(string memory) {
        return "Cash Machine Factory V1";
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
        return interfaceId == 0x01ffc9a7
          || interfaceId == CashLib.FACTORY_ERC165;
    }

    function setCashMachineImpl(address _cashMachineImpl) external onlyOwner {
        cashMachineImpl = _cashMachineImpl;
    }

    function setDefaultStrategy(address _defaultStrategy) external onlyOwner {
        defaultStrategy = _defaultStrategy;
    }

    function predictCashAddress(bytes32 _salt)
        external
        view
        override
        returns(address)
    {
        return Clones.predictDeterministicAddress(cashMachineImpl, _salt);
    }

    function getApprovalAddress() override external view returns(address) {
        return defaultStrategy;
    }

    function mintCash(
        address _token,
        uint256 _banknoteDesign,
        bytes32 _salt,
        address _burnManyHolder,
        address[] calldata _holders,
        uint256[] calldata _nominals,
        uint256[] calldata _designs
    ) external payable override nonReentrant {
        require(_nominals.length == _holders.length, "!lengths");
        require(_designs.length == _holders.length, "!lengthsDesigns");

        address sender = _msgSender();

        uint256 nominalsSum = 0;

        EnumerableSet.UintSet storage checkedDesigns;

        for (uint256 i; i < _holders.length; i++) {
            require(sender != _holders[i], "holder==sender");
            require(!_holders[i].isContract(), "holderContract");
            nominalsSum = nominalsSum.add(_nominals[i]);
            uint256 design = _designs[i];
            if (!checkedDesigns.contains(design)) {
                require(designNft.ownerOf(design) == sender, "designIsNotOwned");
                checkedDesigns.add(design);
            }
        }

        address payable result = payable(Clones.cloneDeterministic(cashMachineImpl, _salt));

        CashMachine cashMachine = CashMachine(result);
        cashMachine.configure(
            _token,
            payable(owner()),
            defaultStrategy,
            address(this),
            sender,
            nominalsSum,
            _burnManyHolder,
            _nominals,
            _holders,
            _designs
        );

        if (_token != CashLib.ETH) {
            IERC20(_token).safeTransferFrom(sender, defaultStrategy, nominalsSum);
        } else {
            require(msg.value >= nominalsSum, "!nominalEth");
            payable(defaultStrategy).sendValue(nominalsSum);
        }
        ICashableStrategy(defaultStrategy).register(result, sender, _token, nominalsSum);

        emit CashMachineCreated(result, cashMachineImpl);
    }

    fallback() external {
        revert("NoFallback");
    }

    receive() payable external {}

}
