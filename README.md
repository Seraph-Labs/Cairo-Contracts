# Seraph Labs

cairo-1 starknet libraries by Seraph Labs

### Install library

Edit `scarb.toml` and add:

```toml
[dependencies]
seraphlabs = {git = "https://github.com/Seraph-Labs/Cairo-Contracts.git", tag = "v0.4.1-rc0"}
```

## Token Libraries

### [ERC721](src/tokens/erc721/erc721.cairo)

| extensions                                                   |         Description          |
| :----------------------------------------------------------- | :--------------------------: |
| [Metadata](src/tokens/erc721/extensions/metadata.cairo)      |  Library for ERC721Metadata  |
| [Ennumerable](src/tokens/erc721/extensions/enumerable.cairo) | Library for ERC721Enumerable |

### [ERC3525](src/tokens/erc3525/erc3525.cairo)

### [ERC2114](src/tokens/erc2114/erc2114.cairo)

> Read the [SNIP](docs/snip-2114.md) to learn more about ERC2114

| extensions                                                           |         Description          |
| :------------------------------------------------------------------- | :--------------------------: |
| [trait_catalog](src/tokens/erc2114/extensions/trait_catalog.cairo)   |          trait list          |
| [slot_attribute](src/tokens/erc2114/extensions/slot_attribute.cairo) |  create attributes for slot  |
| [inventory](src/tokens/erc2114/extensions/inventory.cairo)           | inventory system for ERC2114 |
