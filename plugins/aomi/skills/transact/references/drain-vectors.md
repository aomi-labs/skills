# Recipient and approval review

Check protocol-specific fields that can redirect value. Typical examples include
Uniswap `recipient`, Aave `onBehalfOf`, CCTP `mintRecipient` and bridge `_to`.
Validate each against the user-approved sender/recipient and route intent, along
with token contract, chain, amount, allowance and minimum output.

Read the current Commit simulation's guards and warnings. Their exact policy is
runtime-dependent; do not assume every non-self payment is blocked or that a
warning can always be acknowledged. Surface a guard failure with the affected
field and approved intent. Correct genuine construction errors and obtain a
fresh reviewed simulation. Keep intentional external recipients explicit.

Zero-address or burn-address destinations require particular care. A source
bridge transaction and its recipient field alone do not prove destination
receipt or spendable output. See [workflows.md](workflows.md#reconciliation).
