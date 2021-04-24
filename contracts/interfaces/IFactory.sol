// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;


interface IFactory {
    function mint(uint256 _optionId, address _toAddress, uint256 _amount, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _optionId) public view returns (uint256);
}
