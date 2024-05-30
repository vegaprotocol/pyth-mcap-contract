// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {PythMcap, IndexAsset, PYTH_GNOSIS_MAINNET} from "../src/PythMcap.sol";
import "../src/PriceFeedIDs.sol" as PriceFeedIDs;

import {IPyth} from "pyth-sdk-solidity/IPyth.sol";
import {MockPyth} from "pyth-sdk-solidity/MockPyth.sol";

contract PythMcapTest is Test {
    PythMcap public pythMcap;

    function setUp() public {
        uint256 forkId = vm.createFork("gnosis_mainnet");
        vm.selectFork(forkId);
        pythMcap = new PythMcap(PYTH_GNOSIS_MAINNET);
        IndexAsset[] memory assets = new IndexAsset[](5);

        assets[0] = IndexAsset({ // DOGE -8 0.15
            pythId: PriceFeedIDs.CRYPTO_DOGE_USD,
            totalSupply: 144301176384
        });
        assets[1] = IndexAsset({ // SHIB -10 0.000025
            pythId: PriceFeedIDs.CRYPTO_SHIB_USD,
            totalSupply: 589534086491242
        });
        assets[2] = IndexAsset({ // PEPE -10 0.000010
            pythId: PriceFeedIDs.CRYPTO_PEPE_USD,
            totalSupply: 420690000000000
        });
        assets[3] = IndexAsset({ // WIF -9 2.93
            pythId: PriceFeedIDs.CRYPTO_WIF_USD,
            totalSupply: 998906005
        });
        assets[4] = IndexAsset({ // FLOKI -10 0.00021
            pythId: PriceFeedIDs.CRYPTO_FLOKI_USD,
            totalSupply: 9707798180236
        });

        int256 indexPrice = pythMcap.getIndexPrice(assets);
    }

    function testGetPrice() public {}
}

contract PythMcapMockTest is Test {
    PythMcap public pythMcap;
    MockPyth public pyth;

    function setUp() public {
        pyth = new MockPyth(100, 100);
        pythMcap = new PythMcap(address(pyth));

        bytes[] memory updateData = new bytes[](6);
        updateData[0] =
            pyth.createPriceFeedUpdateData(PriceFeedIDs.CRYPTO_DOGE_USD, 1e8, 0, -8, 100, 0, uint64(block.timestamp));
        updateData[1] =
            pyth.createPriceFeedUpdateData(PriceFeedIDs.CRYPTO_SHIB_USD, 1e10, 0, -10, 100, 0, uint64(block.timestamp));
        updateData[2] =
            pyth.createPriceFeedUpdateData(PriceFeedIDs.CRYPTO_PEPE_USD, 1e10, 0, -10, 100, 0, uint64(block.timestamp));
        updateData[3] =
            pyth.createPriceFeedUpdateData(PriceFeedIDs.CRYPTO_WIF_USD, 1e8, 0, -8, 100, 0, uint64(block.timestamp));
        updateData[4] =
            pyth.createPriceFeedUpdateData(PriceFeedIDs.CRYPTO_FLOKI_USD, 1e10, 0, -10, 100, 0, uint64(block.timestamp));
        updateData[5] =
            pyth.createPriceFeedUpdateData(PriceFeedIDs.CRYPTO_USDT_USD, 1e2, 0, -2, 100, 0, uint64(block.timestamp));
        pyth.updatePriceFeeds{value: 600}(updateData);
    }

    function testMcap() public {
        IndexAsset[] memory assets = new IndexAsset[](5);
        assets[0] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_DOGE_USD, totalSupply: 100});
        assets[1] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_SHIB_USD, totalSupply: 100});
        assets[2] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_PEPE_USD, totalSupply: 100});
        assets[3] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_WIF_USD, totalSupply: 100});
        assets[4] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_FLOKI_USD, totalSupply: 100});

        int256 indexPrice1 = pythMcap.getIndexPrice(assets);
        int256 indexPrice2 = pythMcap.getIndexPrice(assets, 5, -18);
        assertEq(indexPrice1, 1e18, "Index price should be 1e18");
        assertEq(indexPrice2, 1e18, "Index price should be 1e18");

        int256 indexPrice3 = pythMcap.getIndexPrice(assets, 3, -18);
        assertEq(indexPrice3, 1e18, "Index price should be 1e18");

        int256 indexPrice4 = pythMcap.getIndexPrice(assets, 1, -18);
        assertEq(indexPrice4, 1e18, "Index price should be 1e18");
    }

    function testUnevenMcap() public {
        IndexAsset[] memory assets = new IndexAsset[](5);
        assets[0] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_DOGE_USD, totalSupply: 1});
        assets[1] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_SHIB_USD, totalSupply: 10});
        assets[2] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_PEPE_USD, totalSupply: 100});
        assets[3] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_WIF_USD, totalSupply: 1000});
        assets[4] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_FLOKI_USD, totalSupply: 10000});

        int256 indexPrice1 = pythMcap.getIndexPrice(assets);
        int256 indexPrice2 = pythMcap.getIndexPrice(assets, 5, -18);
        assertApproxEqAbs(indexPrice1, 1e18, 10, "Index price should be 1e18");
        assertApproxEqAbs(indexPrice2, 1e18, 10, "Index price should be 1e18");

        int256 indexPrice3 = pythMcap.getIndexPrice(assets, 3, -18);
        assertApproxEqAbs(indexPrice3, 1e18, 10, "Index price should be 1e18");

        int256 indexPrice4 = pythMcap.getIndexPrice(assets, 1, -18);
        assertApproxEqAbs(indexPrice4, 1e18, 10, "Index price should be 1e18");
    }
}

contract PythMcapMockFixtureTest is Test {
    PythMcap public pythMcap;
    MockPyth public pyth;

    function setUp() public {
        pyth = new MockPyth(100, 100);
        pythMcap = new PythMcap(address(pyth));

        bytes[] memory updateData = new bytes[](6);
        updateData[0] = pyth.createPriceFeedUpdateData(
            PriceFeedIDs.CRYPTO_DOGE_USD, 15887476, 0, -8, 100, 0, uint64(block.timestamp)
        );
        updateData[1] = pyth.createPriceFeedUpdateData(
            PriceFeedIDs.CRYPTO_SHIB_USD, 261848, 0, -10, 100, 0, uint64(block.timestamp)
        );
        updateData[2] = pyth.createPriceFeedUpdateData(
            PriceFeedIDs.CRYPTO_PEPE_USD, 135250, 0, -10, 100, 0, uint64(block.timestamp)
        );
        updateData[3] = pyth.createPriceFeedUpdateData(
            PriceFeedIDs.CRYPTO_WIF_USD, 342890970, 0, -8, 100, 0, uint64(block.timestamp)
        );
        updateData[4] = pyth.createPriceFeedUpdateData(
            PriceFeedIDs.CRYPTO_FLOKI_USD, 2444812, 0, -10, 100, 0, uint64(block.timestamp)
        );
        updateData[5] = pyth.createPriceFeedUpdateData(
            PriceFeedIDs.CRYPTO_USDT_USD, 99952083, 0, -8, 100, 0, uint64(block.timestamp)
        );
        pyth.updatePriceFeeds{value: 600}(updateData);
    }

    function testMcap() public {
        IndexAsset[] memory assets = new IndexAsset[](5);
        assets[0] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_DOGE_USD, totalSupply: 144301176384});
        assets[1] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_SHIB_USD, totalSupply: 589534086491242});
        assets[2] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_PEPE_USD, totalSupply: 420690000000000});
        assets[3] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_WIF_USD, totalSupply: 998906005});
        assets[4] = IndexAsset({pythId: PriceFeedIDs.CRYPTO_FLOKI_USD, totalSupply: 9707798180236});

        int256 indexPrice1 = pythMcap.getIndexPrice(assets);
        int256 indexPrice2 = pythMcap.getIndexPrice(assets, 5, -18);
        assertApproxEqAbs(indexPrice1, 308826848718787000, 5000, "Index price should be 1e18");
        assertApproxEqAbs(indexPrice2, 308826848718787000, 5000, "Index price should be 1e18");

        int256 indexPrice3 = pythMcap.getIndexPrice(assets, 3, -18);
        assertApproxEqAbs(indexPrice3, 82732252927982900, 3000, "Index price should be 1e18");

        int256 indexPrice4 = pythMcap.getIndexPrice(assets, 1, -18);
        assertApproxEqAbs(indexPrice4, 158950924514500000, 1000, "Index price should be 1e18");
    }
}
