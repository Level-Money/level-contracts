// SPDX-License-Identifier: UNDEFINED
pragma solidity >=0.8.19;

import {lvlUSD} from "../../src/lvlUSD.sol";

contract MockBurner {
    constructor() {}

    function burn(uint256 _amount, lvlUSD _lvlUSD) public {
        _lvlUSD.burn(_amount);
    }
}
