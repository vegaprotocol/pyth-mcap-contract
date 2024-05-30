# `PythMcap`

> Calculate a weighted index price of a number of assets, optionally considering only the top N assets by market capitalization.

## Documentation


```solidity
interface IPythMcap {
    struct IndexAsset {
        bytes32 pythId;
        uint96 totalSupply;
    }

    /// @notice Get the index price for a list of assets
    /// @param indexAssets List of index assets
    /// @return Index price
    function getIndexPrice(IndexAsset[] calldata indexAssets) public view returns (int256);

    /// @notice Get the index price for top N assets by market cap, returning a price with the given expo
    /// @param indexAssets List of index assets
    /// @param topN Number of assets to consider. If N == indexAssets.length, all assets are considered. If N == 1 only the top asset is considered.
    /// @param expo Exponent to rebase the price to (must be negative, ie. 10 ^ -expo)
    /// @return Index price
    function getIndexPrice(IndexAsset[] calldata indexAssets, uint8 topN, int32 expo) public view returns (int256);

    /// @notice Get the index price quoted in base asset, for top N assets by market cap, returning a price with the given expo
    /// @param indexAssets List of index assets
    /// @param baseAssetId Base asset Pyth ID
    /// @param topN Number of assets to consider
    /// @param expo Exponent to rebase the price to (must be negative, ie. 10 ^ -expo)
    /// @return Index price
    function getIndexPrice(IndexAsset[] calldata indexAssets, bytes32 baseAssetId, uint8 topN, int32 expo)
        public
        view
        returns (int256);
}
```


## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Deploy

```shell
$ forge script script/PythMcap.s.sol:PythMcapScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## License

[MIT](LICENSE)
