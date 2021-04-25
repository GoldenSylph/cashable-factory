// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../../interfaces/ICash.sol";

contract Cash is ERC20PresetMinterPauser, Initializable, ICash {

    constructor() ERC20PresetMinterPauser(
      "Cash Token", "CH"
    ) {}

    function configure(address _strategy) external initializer {
        grantRole(MINTER_ROLE, _strategy);
    }
}
