// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;


import "./OwnableDelegateProxy.sol";

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
