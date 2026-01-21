## About

mux - multiplexer is a general purpose multisig wallet for ao mainnet.

> status: unaudited wip mvp

## Architecture

[src/](./src) is split into wallet + shared modules:

- `src/wallet/` core logic (handlers, internal ops, helpers, codec, patch, getters).
- `src/shared/` common deps/types/helpers/constants.

build output is a single bundled lua process in `build/wallet.lua`.

patch streams are emitted from `wallet/patch.tl`:
- `mux-state` (config/nonce/threshold/deployer/last activity)
- `admins-patch`
- `pending-proposals-patch`
- `full-proposals-patch`
- `executed-proposals-patch`
- `cancelled-proposals-patch`
- `rejected-proposals-patch`

## Core Actions

Public:
- `Configure` initialize admins + threshold (once).
- `Propose` submit a proposal (`msg.Data` JSON of the to-be-execute external process-process call after approval).
- `Vote` vote on a proposal.
- `Execute` try to execute if threshold met.
- `Cancel` cancel own proposal if no other votes.

Internal (mux wallet related state setters):
- `AddAdmin`
- `DeactivateAdmin`
- `AddAuthority`
- `RemoveAuthority`

Proposal payload (msg.Data JSON):
```
{
  "Target": "<process-id>",
  "Action": "<action>",
  "Tags": { "k": "v" } | [{ "name": "k", "value": "v" }],
  "Data": "string"
}
```

## Build

```bash
make build-wallet
```

## Deploy onchain

requires a `wallet.json` file at the root of the repo 

```bash
make deploy-wallet
```
