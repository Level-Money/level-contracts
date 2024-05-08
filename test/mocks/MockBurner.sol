// SPDX-License-Identifier: UNDEFINED
pragma solidity >=0.8.19;

import {lvUSD} from "../../src/lvUSD.sol";

contract MockBurner {
    constructor() {}

    function burn(uint256 _amount, lvUSD _lvUSD) public {
        _lvUSD.burn(_amount);
    }
}
