# Pragma V2

[![GitHub Actions][gha-badge]][gha] [![codecov](https://codecov.io/gh/astraly-labs/pragma-monorepo/branch/main/graph/badge.svg?)](https://codecov.io/gh/astraly-labs/pragma-monorepo) [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/astraly-labs/pragma-monorepo/actions
[gha-badge]: https://github.com/PaulRBerg/prb-math/actions/workflows/ci.yml/badge.svg
[codecov-badge]: https://img.shields.io/codecov/c/github/astraly-labs/pragma-monorepo
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://www.apache.org/licenses/LICENSE-2.0
[license-badge]: https://img.shields.io/badge/License-Apache-blue.svg

## Rust

<a href="./rust/theoros/">Theoros</a>

Request the API to construct the calldata necessary for cross-chain updates.

- Listens for live data feeds update
- Retrieves the signatures of the Hyperlane Validators
- Constructs the calldata for data feeds requested through HTTP/WebSocket

## Solidity

<a href="./solidity/">Solidity SDK</a>

Solidity contracts & libraries.

- Set of contracts used to store data relayed from Pragma chain using Hyperlane.
- SDK that can be used by EVM protocols looking to integrate Pragma.

## Typescript

<a href="./typescript/theoros-sdk/">Theoros SDK</a>

A SDK used to query data from Theoros in a simple way.

- Fetch the latest calldata using either REST or Websocket endpoints.

<a href="./typescript/pragma-deployer/">Pragma Deployer</a>

The main scripts used to deploy all our contracts (Cairo, Solidity, ...) are located there.

<a href="./typescript/pragma-scripts/">Pragma Scripts</a>

Utils scripts that we use to make some actions on-chain.
