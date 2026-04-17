# Contract Addresses

> Last verified: 2026-04-15

This reference only includes the addresses used in the examples for this package.

## Ethereum

| Contract | Address | Notes |
|----------|---------|-------|
| WETH | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` | Canonical wrapped ETH |
| USDC | `0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48` | Canonical USDC on Ethereum mainnet |
| USDT | `0xdAC17F958D2ee523a2206206994597C13D831ec7` | Canonical USDT on Ethereum mainnet |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` | Universal token approval contract |
| Uniswap V3 SwapRouter02 | `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45` | Used for swap examples |
| Chainlink ETH USD feed | `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` | Used for price checks and sanity checks |

## Base

| Contract | Address | Notes |
|----------|---------|-------|
| WETH | `0x4200000000000000000000000000000000000006` | Canonical wrapped ETH on Base |
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | Canonical USDC on Base |

## Arbitrum

| Contract | Address | Notes |
|----------|---------|-------|
| USDC | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | Canonical USDC on Arbitrum |
| WETH | `0x82af49447d8a07e3bd95bd0d56f35241523fbab1` | Canonical wrapped ETH on Arbitrum |

## Polygon

| Contract | Address | Notes |
|----------|---------|-------|
| USDC | `0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174` | Canonical USDC on Polygon |
| WETH | `0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619` | Canonical wrapped ETH on Polygon |

## Usage Notes

- Use these addresses only where the example flow calls for them.
- Keep checksummed casing exactly as written.
- If a target changes, update the verification date and the source note.
- Prefer official docs or block explorer verification before changing anything here.
- If a newer canonical address exists for an example chain, replace it and reverify.
