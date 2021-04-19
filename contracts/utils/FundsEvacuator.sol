// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../lib/CashLib.sol";

contract FundsEvacuator {

    using SafeERC20 for IERC20;
    using Address for address payable;

    address public evacuator;
    bool public anyToken;
    address public tokenToStay;

    modifier onlyEvacuator {
        require(msg.sender == evacuator, "!evacuator");
        _;
    }

    function _setEvacuator(address _evacuator, bool _anyToken) internal {
        evacuator = _evacuator;
        anyToken = _anyToken;
    }

    function _setTokenToStay(address _tokenToStay) internal {
        tokenToStay = _tokenToStay;
    }

    function renounceEvacuator(address _to) external onlyEvacuator {
        evacuator = _to;
    }

    function evacuate(address _otherToken, address payable _to) external onlyEvacuator {
        if (!anyToken) {
            require(_otherToken != tokenToStay, "=tokenToStay");
        }
        if (_otherToken != CashLib.ETH) {
            IERC20 otherTokenERC20 = IERC20(_otherToken);
            otherTokenERC20.safeTransfer(_to, otherTokenERC20.balanceOf(address(this)));
        } else {
            _to.sendValue(address(this).balance);
        }
    }
}
