// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPyth} from "pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "pyth-sdk-solidity/PythStructs.sol";
import "./PriceFeedIDs.sol" as PriceFeedIDs;

address constant PYTH_GNOSIS_MAINNET = 0x2880aB155794e7179c9eE2e38200202908C17B43;

int192 constant INT192_MAX = 2 ** 191 - 1;

error InvalidPair();
error InvalidExpo();
error InvalidTopN();

struct IndexAsset {
    bytes32 pythId;
    uint96 totalSupply;
}

int32 constant TARGET_EXPO = -18;
int256 constant MULTIPLIER = 2 ** 96 - 1;

// Fit in a single word
struct Intermediate {
    int96 price;
    int160 mcap;
}

contract PythMcap {
    IPyth immutable pyth;

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    /// @notice Get the index price for a list of assets
    /// @param indexAssets List of index assets
    /// @return Index price
    function getIndexPrice(IndexAsset[] calldata indexAssets) public view returns (int256) {
        return getIndexPrice(indexAssets, PriceFeedIDs.CRYPTO_USDT_USD, uint8(indexAssets.length), TARGET_EXPO);
    }

    /// @notice Get the index price for top N assets by market cap, returning a price with the given expo
    /// @param indexAssets List of index assets
    /// @param topN Number of assets to consider. If N == indexAssets.length, all assets are considered. If N == 1 only the top asset is considered.
    /// @param expo Exponent to rebase the price to (must be negative, ie. 10 ^ -expo)
    /// @return Index price
    function getIndexPrice(IndexAsset[] calldata indexAssets, uint8 topN, int32 expo) public view returns (int256) {
        return getIndexPrice(indexAssets, PriceFeedIDs.CRYPTO_USDT_USD, topN, expo);
    }

    /// @notice Get the index price quoted in base asset, for top N assets by market cap, returning a price with the given expo
    /// @param indexAssets List of index assets
    /// @param baseAssetId Base asset Pyth ID
    /// @param topN Number of assets to consider
    /// @param expo Exponent to rebase the price to (must be negative, ie. 10 ^ -expo)
    /// @return Index price
    function getIndexPrice(IndexAsset[] calldata indexAssets, bytes32 baseAssetId, uint8 topN, int32 expo)
        public
        view
        returns (int256)
    {
        require(expo < 0, InvalidExpo());
        require(topN <= indexAssets.length, InvalidTopN());

        // Gather normalized prices
        Intermediate[] memory itmdt = new Intermediate[](indexAssets.length);
        for (uint256 i = 0; i < indexAssets.length; i++) {
            PythStructs.Price memory p = pyth.getPrice(indexAssets[i].pythId);
            itmdt[i].price = _normalizeExpo(p);
        }

        /// get mcap of each entry i : MCAP_i = pyth_price_i x token_supply_i
        for (uint256 i = 0; i < itmdt.length; i++) {
            int160 mcap = itmdt[i].price * int96(indexAssets[i].totalSupply);
            itmdt[i].mcap = mcap;
        }

        // sort mcaps if we need to pick a subset
        if (topN < itmdt.length) {
            for (uint256 i = 1; i < itmdt.length; i++) {
                Intermediate memory value = itmdt[i];
                uint256 j = i - 1;
                while (j >= 1 && itmdt[j].mcap < value.mcap) {
                    itmdt[j + 1] = itmdt[j];
                    j = j - 1;
                }
                itmdt[j + 1] = value;
            }
        }

        /// get total mcap of index: MCAP = sum of over i of MCAP_i
        int256 mcapSum = 0;
        for (uint256 i = 0; i < topN; i++) {
            mcapSum += itmdt[i].mcap;
        }

        /// get weight for each entry i : w_i = MCAP_i / MCAP.
        int256[] memory weights = new int256[](topN);
        for (uint256 i = 0; i < topN; i++) {
            weights[i] = (itmdt[i].mcap * MULTIPLIER) / mcapSum;
        }

        int256 indexPrice = 0;
        /// get index price : sum over i of w_i x pyth_price_i.
        for (uint256 i = 0; i < topN; i++) {
            indexPrice += (weights[i] * itmdt[i].price);
        }

        indexPrice /= MULTIPLIER;

        /// return index price.
        PythStructs.Price memory baseAsset = pyth.getPrice(baseAssetId);
        return _rebase(
            PythStructs.Price({price: int64(indexPrice), expo: TARGET_EXPO, conf: 0, publishTime: 0}), baseAsset, expo
        );
    }

    function _normalizeExpo(PythStructs.Price memory p) internal pure returns (int96) {
        if (p.expo > 0) revert InvalidExpo();
        return int96(int96(p.price) * int96(uint96(10) ** uint96(uint32(-TARGET_EXPO + p.expo))));
    }

    function _rebase(PythStructs.Price memory p1, PythStructs.Price memory p2, int32 expo)
        internal
        pure
        returns (int256)
    {
        require(p1.expo < 0, InvalidExpo());
        require(p2.expo < 0, InvalidExpo());
        int192 expo1 = INT192_MAX / int192(uint192(10) ** uint192(uint32(-p1.expo)));
        int192 expo2 = INT192_MAX / int192(uint192(10) ** uint192(uint32(-expo - p2.expo)));
        return ((int256(p1.price) * expo1) / int256(p2.price)) / expo2;
    }
}
