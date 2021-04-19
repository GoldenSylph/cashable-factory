// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

contract ERC165Generator {

    // factory
    function getApprovalAddress() external view returns(address) { return address(0); }
    function predictCashAddress(bytes32 _salt) external view returns(address) { return address(0); }
    function mintCash(
        bytes32 _salt,
        address _token,
        address[] memory _holders,
        uint256[] memory _nominals
    ) external payable {}

    // machine
    function burn(address payable _to, uint256 _id) external {}

    // strategy
    function register(address _cashMachine, address _token, uint256 _amount) external {}
    function withdraw(uint256 _amount) external {}
    function harvest() external {}

    function erc165Factory() external returns(bytes4) {
        return this.getApprovalAddress.selector ^ this.predictCashAddress.selector ^ this.mintCash.selector;
    }

    function erc165Machine() external returns(bytes4) {
        return this.burn.selector;
    }

    function erc165Strategy() external returns(bytes4) {
        return this.register.selector ^ this.withdraw.selector ^ this.harvest.selector;
    }

}
