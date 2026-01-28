## About

mux - multiplexer is a general purpose multisig wallet for ao mainnet - web interface available at [treasury.ao](https://treasury.ao)

![](https://load0.network/resolve/0x620eeca6246c1c167853c7cb1604f47ec9dbce79b16a4d2c95bac58219fc92d2)

> status: unaudited wip mvp - DO NOT USE IT IN ANY PRODUCTION ENVIROMENT

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

Proposal payload (`msg.Data` JSON):

```json
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
# or
make build
```

## Deploy onchain

requires a `wallet.json` file at the root of the repo 

```bash
make deploy-wallet
```

## Important N.Bs

* `mux` is under unaudited test releases, do not use it in production
* `mux` will be usable along popular ao network tokens (e.g. $AO and $PI) once those tokens are on mainnet's greezones - authority UX issues
* do not expect stability before a public stable release, bug reports are welcome, please open an issue!

## Test scripts
check [scripts](./scripts/) for JS `@permaweb/aoconnect` test scripts

## HyperPATHs
The `patch@1.0` HyperPATHs that are exposed from mux v0.1.3 are:

* `admins`: exposes the `admins-patch` under `admins` hyperpath 

```bash
curl https://app-1.forward.computer/<PROCESS_ID>~process@1.0/now/cache/admins/serialize~json@1.0
```

* `mux_state`: exporer the `mux-state-patch` table under the `mux_state` hyperpath

```bash
curl https://app-1.forward.computer/<PROCESS_ID>~process@1.0/now/cache/mux_state/serialize~json@1.0
```

## License
This project is licensed under the [BSL 1.1](./LICENSE) license