// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IFactoryERC721.sol";
import "./CashDesign.sol";
import "./CashDesignLootBox.sol";
import "../../lib/StringsConcatenations.sol";

contract CashDesignFactory is FactoryERC721, Ownable {
    using StringsConcatenations for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    address public lootBoxNftAddress;
    string public baseURI = "https://creatures-api.opensea.io/api/factory/";

    /*
     * Enforce the existence of only 100 OpenSea creatures.
     */
    uint256 CASH_DESIGN_SUPPLY = 100;

    /*
     * Three different options for minting Cash Designs (basic, premium, and gold).
     */
    uint256 NUM_OPTIONS = 3;
    uint256 SINGLE_CASH_DESIGN_OPTION = 0;
    uint256 MULTIPLE_CASH_DESIGN_OPTION = 1;
    uint256 LOOTBOX_OPTION = 2;
    uint256 NUM_CASH_DESIGNS_IN_MULTIPLE_CASH_DESIGN_OPTION = 4;

    constructor(address _proxyRegistryAddress, address _nftAddress) public {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        lootBoxNftAddress = address(
            new CashDesignLootBox(_proxyRegistryAddress, address(this))
        );

        fireTransferEvents(address(0), owner());
    }

    function name() external view returns(string memory) {
        return "Cash Design Item Sale";
    }

    function symbol() external view returns(string memory) {
        return "CDF";
    }

    function supportsFactoryInterface() public view returns(bool) {
        return true;
    }

    function numOptions() public view returns(uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == msg.sender ||
                owner() == msg.sender ||
                msg.sender == lootBoxNftAddress
        );
        require(canMint(_optionId));

        CashDesign cashDesign = CashDesign(nftAddress);
        if (_optionId == SINGLE_CASH_DESIGN_OPTION) {
            cashDesign.mintTo(_toAddress);
        } else if (_optionId == MULTIPLE_CASH_DESIGN_OPTION) {
            for (
                uint256 i = 0;
                i < NUM_CASH_DESIGNS_IN_MULTIPLE_CASH_DESIGN_OPTION;
                i++
            ) {
                cashDesign.mintTo(_toAddress);
            }
        } else if (_optionId == LOOTBOX_OPTION) {
            CashDesignLootBox cashDesignLootBox = CashDesignLootBox(
                lootBoxNftAddress
            );
            cashDesignLootBox.mintTo(_toAddress);
        }
    }

    function canMint(uint256 _optionId) public view returns(bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        CashDesign cashDesign = CashDesign(nftAddress);
        uint256 cashDesignSupply = cashDesign.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_CASH_DESIGN_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == MULTIPLE_CASH_DESIGN_OPTION) {
            numItemsAllocated = NUM_CASH_DESIGNS_IN_MULTIPLE_CASH_DESIGN_OPTION;
        } else if (_optionId == LOOTBOX_OPTION) {
            CashDesignLootBox cashDesignLootBox = CashDesignLootBox(
                lootBoxNftAddress
            );
            numItemsAllocated = cashDesignLootBox.itemsPerLootbox();
        }
        return cashDesignSupply < (CASH_DESIGN_SUPPLY - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) external view returns(string memory) {
        return StringsConcatenations.strConcat(baseURI, StringsConcatenations.uint2str(_optionId));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns(bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns(address _owner) {
        return owner();
    }
}
