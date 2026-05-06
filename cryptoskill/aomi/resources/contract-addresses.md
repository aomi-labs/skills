# Contract Addresses

> **Last verified:** April 2026 (v0.1.30 captures, mainnet + L2)
> **Verification:** `cast code <address> --rpc-url $RPC_URL` for AA stack contracts; protocol contracts cross-checked against [resources/supported-apps.md](supported-apps.md) entries staged by the agent.

The aomi CLI does not deploy its own contracts. The addresses below are the AA-stack and protocol contracts the CLI signs through or commonly stages calls to. They are listed here for grep-ability and to help operators debug a queued transaction's `to:` field.

For per-chain protocol addresses (Aave on Arbitrum, Uniswap on Polygon, etc.), the agent picks them at request time from the active app's registry. Run `aomi app list` to see which apps are loaded.

## EIP-7702 Delegation Contract

The EOA's `code` slot points at this address after the first 7702 transaction. This is the Alchemy Modular Account v2 implementation.

| Contract | Ethereum |
|----------|----------|
| Modular Account v2 (delegation target) | `0x69007702764179f14F51cdce752f4f775d74E139` |

The same delegation contract is used across all chains where 7702 is enabled (Ethereum mainnet + L2s that have activated EIP-7702).

## ERC-4337 EntryPoint

EntryPoint v0.7 is deployed at the same singleton address across every EVM chain that supports ERC-4337.

| Contract | All EVM chains |
|----------|----------------|
| EntryPoint v0.7 | `0x0000000071727De22E5E9d8BAf0edAc6f37da032` |

EntryPoint v0.6 (`0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789`) is still deployed for legacy compatibility but the CLI targets v0.7 by default.

## Commonly Staged Protocol Contracts (Ethereum mainnet)

These are the contracts the agent most often stages calls to in the [examples/](../examples/) walkthroughs. Not exhaustive — the agent has registries for 25+ apps; this table is a sample.

### DEX

| Contract | Address |
|----------|---------|
| Uniswap V3 SwapRouter02 | `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45` |
| Uniswap V3 Factory | `0x1F98431c8aD98523631AE4a59f267346ea31F984` |
| Sushi V2 Router | `0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F` |
| Curve Router (NG) | `0x16C6521Dff6baB339122a0FE25a9116693265353` |

### Lending

| Contract | Address |
|----------|---------|
| Aave V3 Pool | `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2` |
| Aave V3 Pool Addresses Provider | `0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e` |
| Compound V3 cUSDCv3 | `0xc3d688B66703497DAA19211EEdff47f25384cdc3` |
| Morpho Blue | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` |

### Liquid Staking

| Contract | Address |
|----------|---------|
| Lido stETH | `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84` |
| Lido wstETH | `0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0` |
| Rocket Pool RocketDepositPool | `0xDD3f50F8A6CafbE9b31a427582963f465E745AF8` |
| EtherFi LiquidityPool | `0x308861A430be4cce5502d0A12724771Fc6DaF216` |

### Bridges

| Contract | Address |
|----------|---------|
| CCTP TokenMessenger v1 | `0x28b5a0e9c621a5badaa536219b3a228c8168cf5d` |
| Across SpokePool (Ethereum) | `0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5` |
| Stargate Router | `0x8731d54E9D02c286767d56ac03e8037C07e01e98` |
| Base L1StandardBridge | `0x3154cf16ccdb4c6d922629664174b904d80f2c35` |
| Optimism L1StandardBridge | `0x99c9fc46f92e8a1c0dec1b1747d010903e884be1` |

### Tokens

| Token | Ethereum Address |
|-------|------------------|
| USDC | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| USDT | `0xdAC17F958D2ee523a2206206994597C13D831ec7` |
| DAI | `0x6B175474E89094C44Da98b954EedeAC495271d0F` |
| WETH | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` |
| WBTC | `0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599` |

## L2 Equivalents (sample)

The Aave V3 Pool, for example, is deployed at different addresses per chain. The agent resolves these at request time from the app's registry — these are listed for reference only.

| Contract | Arbitrum | Optimism | Base | Polygon |
|----------|----------|----------|------|---------|
| Aave V3 Pool | `0x794a61358D6845594F94dc1DB02A252b5b4814aD` | `0x794a61358D6845594F94dc1DB02A252b5b4814aD` | `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5` | `0x794a61358D6845594F94dc1DB02A252b5b4814aD` |
| USDC (native) | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | `0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` |
| WETH | `0x82aF49447D8a07e3bd95BD0d56f35241523fBab1` | `0x4200000000000000000000000000000000000006` | `0x4200000000000000000000000000000000000006` | `0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619` |

## Verifying an Address

Before signing a transaction, you can verify the `to:` address is what you expect by:

1. **Check the queued tx's metadata.**

```bash
aomi tx list
# Look at the label and to: field
```

2. **Verify the contract is live.**

```bash
cast code 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 --rpc-url $ETH_RPC_URL
# Returns bytecode if deployed; "0x" if no contract at that address
```

3. **Cross-check against the protocol's official docs.** The skill's job is to surface what the agent staged; final verification is the user's responsibility for high-value transactions.

## Deprecated / Do Not Use

| Contract | Address | Replaced By |
|----------|---------|-------------|
| Uniswap V3 SwapRouter (V1) | `0xE592427A0AEce92De3Edee1F18E0157C05861564` | SwapRouter02 `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45` |
| EntryPoint v0.6 | `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789` | EntryPoint v0.7 `0x0000000071727De22E5E9d8BAf0edAc6f37da032` |
| Aave V2 LendingPool | `0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9` | Aave V3 Pool `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2` |

The agent will not stage calls to deprecated contracts unless the user explicitly names them, in which case it should warn and offer to use the current version.
