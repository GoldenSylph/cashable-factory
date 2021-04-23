// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


library CashLib {

    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bytes4 public constant CASHABLE_AAVE_STRATEGY_ERC165 = 0x32b7089b;
    bytes4 public constant MACHINE_ERC165 = 0x9dc29fac;
    bytes4 public constant FACTORY_ERC165 = 0xd821a987;

    struct Cash {
        uint256 id;
        address holder;
        uint256 nominal;
        uint256 design;
    }

    struct CashSet {
        EnumerableSet.UintSet ids;
        EnumerableSet.AddressSet holders;
        EnumerableSet.UintSet nominals;
        EnumerableSet.UintSet designs;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(CashSet storage set, Cash memory value) internal returns(bool) {
        return
            set.ids.add(value.id) &&
            set.holders.add(value.holder) &&
            set.nominals.add(value.nominal) &&
            set.designs.add(value.design);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(CashSet storage set, Cash memory value) internal returns(bool) {
        return
            set.ids.remove(value.id) &&
            set.holders.remove(value.holder) &&
            set.nominals.remove(value.nominal) &&
            set.designs.remove(value.design);
    }

    /**
     * @dev Removes a value from a set by index. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function removeAt(CashSet storage set, uint256 index) internal returns(bool) {
      return
          set.ids.remove(set.ids.at(index)) &&
          set.holders.remove(set.holders.at(index)) &&
          set.nominals.remove(set.nominals.at(index)) &&
          set.designs.remove(set.designs.at(index));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(CashSet storage set, Cash memory value) internal view returns(bool) {
        return set.ids.contains(value.id);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(CashSet storage set) internal view returns(uint256) {
        return set.ids.length();
    }

   /**
    * @dev Returns the id of cash stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function atId(CashSet storage set, uint256 index) internal view returns(uint256 _id) {
        return set.ids.at(index);
    }

    /**
     * @dev Returns the holder of cash stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function atHolder(CashSet storage set, uint256 index) internal view returns(address _holder) {
        return set.holders.at(index);
    }

    /**
     * @dev Returns the nominal of cash stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function atNominal(CashSet storage set, uint256 index) internal view returns(uint256 _nominal) {
        return set.nominals.at(index);
    }

    /**
     * @dev Returns the ID of Cash Design NFT of cash stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function atDesign(CashSet storage set, uint256 index) internal view returns(uint256 _design) {
        return set.designs.at(index);
    }

}
