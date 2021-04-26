// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;


interface ICashMachineFactory {
    function getApprovalAddress() external view returns(address);
    function predictCashAddress(bytes32 _salt) external view returns(address);
    function mintCash(
        address _token,
        uint256 _banknoteDesign,
        bytes32 _salt,
        address _burnManyHolder,
        address[] calldata _holders,
        uint256[] calldata _nominals,
        uint256[] calldata _designs
    ) external payable;
}
