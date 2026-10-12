# ERC1155 Token Bonding Curve

Experimental ERC-1155 contracts where each token id has its own Bancor-style
bonding curve (`BancorFormula.sol` / `Power.sol`). Anyone can create a new id
with `createNewToken(reserveRatio, initialSupply, initialPoolBalance)`, then
`mint` / `burn` against that id's curve.

> **Status: prototype, not audited, not safe to deploy.** See "Known issues".

## Contracts

| File | Contract name | Notes |
| --- | --- | --- |
| `contracts/ERC1155BondingCurve.sol` | `ERC1155BondingCurveERC20` | Base curve logic (name duplicates the ERC20 variant) |
| `contracts/ERC1155BondingCurveERC20.sol` | `ERC1155BondingCurveERC20` | Also inherits OpenZeppelin `ERC20` |
| `contracts/ERC1155BondingCurveEth.sol` | `ERC1155BondingCurveEth` | Adds `sendEther` |
| `contracts/ERC1155BondingCurveWeth.sol` | `ERC1155BondingCurveEth` | Same as the Eth variant (name not yet changed) |
| `contracts/BancorFormula.sol`, `Power.sol`, `SafeMath.sol` | | Bancor purchase/sale math |
| `contracts/Lock.sol` | `Lock` | Hardhat template sample, unrelated |

Reserve ratio is in ppm (1 to 1,000,000): 1/3 ≈ quadratic price, 1/2 ≈ linear, 2/3 ≈ square root.

## Build

Hardhat (configured for solc 0.8.24 in `hardhat.config.ts`):

```sh
npm install
npx hardhat compile
```

Or with Foundry, without touching the repo layout:

```sh
forge build --contracts contracts \
  --remappings @openzeppelin/=node_modules/@openzeppelin/ \
  --out /tmp/erc-out --cache-path /tmp/erc-cache
```

There are no tests for the bonding-curve contracts yet (`test/Lock.ts` is the
Hardhat sample).

## Known issues

Found by reading the code; none are fixed yet.

- `mint` takes no payment: the "deposit" argument is a number, no ETH/ERC20 is collected.
- `mint` / `burn` never update `poolBalances` or `totalSupplies`, so the price never moves; `burn` pays nothing out.
- `sendEther` (Eth/Weth variants) lets **any caller** send the contract's ETH to any address.
- `setMaxGasPrice` has no access control.
- Two pairs of files declare the same contract name, which breaks artifact lookup by name.
