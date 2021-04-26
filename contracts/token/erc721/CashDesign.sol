// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "./ERC721Tradable.sol";

/**
 * @title CashDesign
 * Creature - a contract for my non-fungible creatures.
 */
contract CashDesign is ERC721Tradable {

    constructor(address _proxyRegistryAddress)
        public
        ERC721Tradable("Cash Design", "CHDN", _proxyRegistryAddress)
    {}

    function baseTokenURI() public override pure returns(string memory) {
        return "https://creatures-api.opensea.io/api/creature/";
    }

    function contractURI() public pure returns(string memory) {
        return "https://creatures-api.opensea.io/contract/opensea-creatures";
    }
}
