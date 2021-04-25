// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;


interface ICashMachineFactory {
    function getApprovalAddress() external view returns(address);
    function predictCashAddress(bytes32 _salt) external view returns(address);
    function mintCash(
        bytes32 _salt,
        address _token,
        address _burnManyHolder,
        address[] memory _holders,
        uint256[] memory _nominals
    ) external payable;
}
