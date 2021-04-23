// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;


interface ICashMachine {
    function burn(address payable _to, uint256 _id) external;
    function burnMany(address payable _to, uint256[] _ids) external;
    function creator() external view returns(address);
    function nominalsSum() external view returns(uint256);
    function token() external view returns(address);
}
