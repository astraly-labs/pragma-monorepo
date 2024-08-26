# Pragma

[![GitHub Actions][gha-badge]][gha] [![codecov](https://codecov.io/gh/astraly-labs/pragma-monorepo/branch/main/graph/badge.svg?)](https://codecov.io/gh/astraly-labs/pragma-monorepo) [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/astraly-labs/pragma-monorepo/actions
[gha-badge]: https://github.com/PaulRBerg/prb-math/actions/workflows/ci.yml/badge.svg
[codecov-badge]: https://img.shields.io/codecov/c/github/astraly-labs/pragma-monorepo
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://www.apache.org/licenses/LICENSE-2.0
[license-badge]: https://img.shields.io/badge/License-Apache-blue.svg

## CLI

<a href="./cli/">Pragma CLI</a>

CLI used to interact with the Pragma protocol.

- Register yourself as a data provider
- Schedule new data feeds
- Connect pragma to your protocol

## Solidity

<a href="./solidity/">Solidity SDK</a>

Solidity contracts & libraries.

- Set of contracts used to store data relayed from Pragma chain using Hyperlane.
- SDK that can be used by EVM protocols looking to integrate Pragma.

## Local Development

### Foundry

First ensure you have Foundry installed on your machine.

Run the following to install `foundryup`:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

Then run `foundryup` to install `forge`, `cast`, `anvil` and `chisel`.

```bash
foundryup
```

Check out the [Foundry Book](https://book.getfoundry.sh/getting-started/installation) for more information.
