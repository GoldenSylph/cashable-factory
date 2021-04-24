// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICash is IERC20 {
    function mint(address to, uint256 amount) external;
    function setShare(address to, uint256 share) external;
}
