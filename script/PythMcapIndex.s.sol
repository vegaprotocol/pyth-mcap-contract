// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {PythMcapIndex, PYTH_GNOSIS_MAINNET} from "../src/PythMcapIndex.sol";

contract PythMcapIndexScript is Script {
    function run() external {
        vm.startBroadcast(0x21Ff2eD68A806803676D092dDBE2A5789ce2d51D);

        PythMcapIndex pythMcapIndex = new PythMcapIndex(PYTH_GNOSIS_MAINNET);

        vm.stopBroadcast();
    }
}
